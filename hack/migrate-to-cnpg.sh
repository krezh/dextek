#!/usr/bin/env bash
# migrate-to-cnpg.sh
# Plan and execute a migration from crunchy-postgres → cloudnative-pg (CNPG).
#
# Usage:
#   migrate-to-cnpg.sh [--dry-run] [--auto-approve] [--exclude=db1,db2,...] [--verify]
#
#   --dry-run          Show the migration plan and exit; make no changes.
#   --auto-approve     Show the plan and proceed without interactive prompts.
#   --exclude=db1,...  Comma-separated list of databases to exclude from migration.
#   --verify           Skip migration; compare row checksums between source and CNPG.
#
# Interactive mode (default, requires gum):
#   Step 1 — select which databases to migrate.
#   Step 2 — from databases that already have data on CNPG, optionally select which
#             to DROP before migrating (separate prompt, clearly marked destructive).
#
# Prerequisites:
#   - kubectl configured and pointing at the cluster
#   - CNPG cluster is Ready and managed roles have been reconciled
#   - gum (https://github.com/charmbracelet/gum) unless --auto-approve is set

set -euo pipefail

NS="databases"
DRY_RUN=false
AUTO_APPROVE=false
VERIFY_ONLY=false
SCRIPT_START=$(date +%s)
declare -A EXCLUDED_DBS

# Extensions that require shared_preload_libraries — cannot be pre-created and
# their restore errors are safe to ignore.
PRELOAD_EXTENSIONS=(pgaudit pg_stat_statements)

# ── args ────────────────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=true ;;
    --auto-approve)   AUTO_APPROVE=true ;;
    --verify)         VERIFY_ONLY=true ;;
    --exclude=*)
      IFS=',' read -ra _exc <<< "${arg#--exclude=}"
      for _db in "${_exc[@]}"; do EXCLUDED_DBS["$_db"]=1; done
      ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

# ── colours ─────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'    C_BOLD=$'\033[1m'    C_DIM=$'\033[2m'
  C_GREEN=$'\033[0;32m' C_YELLOW=$'\033[0;33m' C_RED=$'\033[0;31m'
  C_CYAN=$'\033[0;36m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN=''
fi

SYM_OK=$'\xe2\x9c\x93'    # ✓
SYM_FAIL=$'\xe2\x9c\x97'  # ✗
SYM_WARN=$'\xe2\x9a\xa0'  # ⚠

# ── logging ─────────────────────────────────────────────────────────────────────

log()  { printf '%s[%s]%s %s\n'          "$C_DIM"    "$(date +%T)" "$C_RESET" "$*"; }
ok()   { printf '%s[%s] %s %s%s\n' "$C_GREEN" "$(date +%T)" "$SYM_OK" "$*" "$C_RESET"; }
warn() { printf '%s[%s] WARN: %s%s\n'    "$C_YELLOW" "$(date +%T)" "$*"  "$C_RESET" >&2; }
die()  { printf '%s[%s] ERROR: %s%s\n'   "$C_RED"    "$(date +%T)" "$*"  "$C_RESET" >&2; exit 1; }

section() {
  echo ""
  printf '%s%s%s\n' "$C_BOLD" '══════════════════════════════════════════════' "$C_RESET"
  printf '%s %s%s\n' "$C_BOLD" "$*" "$C_RESET"
  printf '%s%s%s\n' "$C_BOLD" '══════════════════════════════════════════════' "$C_RESET"
}

elapsed() {
  local secs=$(( $(date +%s) - SCRIPT_START ))
  printf '%dm%02ds' $(( secs / 60 )) $(( secs % 60 ))
}

# ── pod discovery ────────────────────────────────────────────────────────────────

section "Discovering pods"

CRUNCHY_POD=$(kubectl get pods -n "$NS" \
  -l "postgres-operator.crunchydata.com/cluster=postgres,postgres-operator.crunchydata.com/data=postgres" \
  --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
[[ -z "$CRUNCHY_POD" ]] && die "no running crunchy postgres data pod found in namespace '$NS'"

CNPG_POD=$(kubectl get cluster postgres -n "$NS" \
  -o jsonpath='{.status.currentPrimary}' 2>/dev/null || true)
[[ -z "$CNPG_POD" ]] && die "CNPG cluster has no currentPrimary — is the cluster Ready?"

log "Source pod : $CRUNCHY_POD"
log "Target pod : $CNPG_POD"

# ── wait for CNPG cluster ────────────────────────────────────────────────────────

section "Waiting for CNPG cluster"

if ! kubectl wait cluster postgres -n "$NS" --for=condition=Ready --timeout=120s; then
  kubectl describe cluster postgres -n "$NS" | grep -A10 "Conditions:" >&2 || true
  die "CNPG cluster did not become Ready within 120s"
fi
ok "Cluster is Ready"

# ── helpers ──────────────────────────────────────────────────────────────────────

csql() { kubectl exec -n "$NS" "$CRUNCHY_POD" -c database -- psql -U postgres -tAq "$@"; }
nsql() { kubectl exec -n "$NS" "$CNPG_POD"   -c postgres  -- psql -U postgres -tAq "$@"; }

# ── gather source state (crunchy) ────────────────────────────────────────────────

section "Gathering source state (crunchy)"

declare -A DB_OWNER DB_SIZE DB_TABLES DB_EXTENSIONS
DB_LIST=()

while IFS='|' read -r db owner; do
  [[ -z "$db" ]] && continue
  DB_LIST+=("$db")
  DB_OWNER["$db"]="$owner"
done < <(csql -c "
  SELECT d.datname, r.rolname
  FROM pg_database d
  JOIN pg_roles r ON r.oid = d.datdba
  WHERE d.datname NOT IN ('postgres','template0','template1','template2')
  ORDER BY d.datname
" 2>/dev/null) || die "failed to query databases from crunchy — check pod connectivity"

[[ ${#DB_LIST[@]} -eq 0 ]] && die "no user databases found in crunchy — check pod and permissions"

for db in "${DB_LIST[@]}"; do
  DB_SIZE["$db"]=$(csql -c "SELECT pg_size_pretty(pg_database_size('$db'))" 2>/dev/null || echo "?")
  DB_TABLES["$db"]=$(csql -d "$db" -c "
    SELECT count(*) FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog','information_schema')" 2>/dev/null || echo "?")
  DB_EXTENSIONS["$db"]=$(csql -d "$db" -c "
    SELECT string_agg(extname, ',' ORDER BY extname)
    FROM pg_extension WHERE extname <> 'plpgsql'" 2>/dev/null || echo "")
done


log "Found ${#DB_LIST[@]} database(s): ${DB_LIST[*]}"

# All non-system roles from crunchy
declare -A ROLE_LOGIN ROLE_SUPER ROLE_REPLICATION ROLE_CREATEROLE ROLE_CREATEDB
SRC_ROLES=()

while IFS='|' read -r role login super replication createrole createdb; do
  [[ -z "$role" ]] && continue
  SRC_ROLES+=("$role")
  ROLE_LOGIN["$role"]="$login"
  ROLE_SUPER["$role"]="$super"
  ROLE_REPLICATION["$role"]="$replication"
  ROLE_CREATEROLE["$role"]="$createrole"
  ROLE_CREATEDB["$role"]="$createdb"
done < <(csql -c "
  SELECT rolname,
         CASE WHEN rolcanlogin    THEN 'LOGIN'        ELSE 'NOLOGIN'       END,
         CASE WHEN rolsuper       THEN 'SUPERUSER'    ELSE 'NOSUPERUSER'   END,
         CASE WHEN rolreplication THEN 'REPLICATION'  ELSE 'NOREPLICATION' END,
         CASE WHEN rolcreaterole  THEN 'CREATEROLE'   ELSE 'NOCREATEROLE'  END,
         CASE WHEN rolcreatedb    THEN 'CREATEDB'     ELSE 'NOCREATEDB'    END
  FROM pg_roles
  WHERE rolname NOT IN (
    'postgres','pg_monitor','pg_read_all_settings','pg_read_all_stats',
    'pg_stat_scan_tables','pg_signal_backend','pg_read_server_files',
    'pg_write_server_files','pg_execute_server_program','pg_checkpoint',
    'pg_maintain','pg_use_reserved_connections','pg_create_subscription',
    'pg_database_owner'
  )
    AND rolname NOT LIKE 'pg_%'
    AND rolname NOT LIKE '_crunchy%'
    AND rolname NOT LIKE 'crunchyrep%'
    AND rolname NOT LIKE 'pgbackrest%'
    AND rolname NOT LIKE 'replication%'
    AND rolname NOT LIKE 'ccp_%'
    AND rolname NOT LIKE '<%>'
    AND rolname <> 'streaming_replica'
  ORDER BY rolname
" 2>/dev/null) || die "failed to query roles from crunchy"

log "Found ${#SRC_ROLES[@]} non-system role(s)${SRC_ROLES[*]:+: ${SRC_ROLES[*]}}"

# ── gather target state (CNPG) ──────────────────────────────────────────────────

section "Gathering target state (CNPG)"

declare -A DST_DB_EXISTS DST_DB_TABLES
DST_DB_LIST=()

while IFS= read -r db; do
  [[ -z "$db" ]] && continue
  DST_DB_LIST+=("$db")
  DST_DB_EXISTS["$db"]=1
done < <(nsql -c "
  SELECT datname FROM pg_database
  WHERE datname NOT IN ('postgres','template0','template1','app')
  ORDER BY datname
" 2>/dev/null) || warn "failed to query CNPG databases — assuming none exist"

for db in "${DST_DB_LIST[@]}"; do
  _cnt=$(nsql -d "$db" -c "
    SELECT count(*) FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog','information_schema')" 2>/dev/null || true)
  # If the query fails, treat as non-empty (safe default — prevents accidental restore into a live DB)
  DST_DB_TABLES["$db"]="${_cnt:-1}"
done

declare -A DST_ROLE_EXISTS
DST_ROLES=()

while IFS= read -r role; do
  [[ -z "$role" ]] && continue
  DST_ROLES+=("$role")
  DST_ROLE_EXISTS["$role"]=1
done < <(nsql -c "
  SELECT rolname FROM pg_roles
  WHERE rolname NOT IN (
    'postgres','pg_monitor','pg_read_all_settings','pg_read_all_stats',
    'pg_stat_scan_tables','pg_signal_backend','pg_read_server_files',
    'pg_write_server_files','pg_execute_server_program','pg_checkpoint',
    'pg_maintain','pg_use_reserved_connections','pg_create_subscription',
    'pg_database_owner','streaming_replica'
  )
    AND rolname NOT LIKE 'pg_%'
    AND rolname NOT LIKE 'cnpg_%'
  ORDER BY rolname
" 2>/dev/null) || warn "failed to query CNPG roles — assuming none exist"

# Extension availability on CNPG (cached)
declare -A EXT_AVAILABLE

ext_available() {
  local ext="$1"
  if [[ ! -v "EXT_AVAILABLE[$ext]" ]]; then
    local avail
    avail=$(nsql -c "SELECT 1 FROM pg_available_extensions WHERE name='$ext'" 2>/dev/null || echo "")
    EXT_AVAILABLE["$ext"]="${avail:-0}"
  fi
  [[ "${EXT_AVAILABLE[$ext]}" == "1" ]]
}

log "CNPG has ${#DST_DB_LIST[@]} database(s), ${#DST_ROLES[@]} role(s)"

# ── compute plan ─────────────────────────────────────────────────────────────────

declare -A DB_ACTION  # create | restore | skip | exclude | drop_restore
TO_CREATE=0
TO_RESTORE=0
TO_SKIP=0
TO_EXCLUDE=0

for db in "${DB_LIST[@]}"; do
  if [[ "${EXCLUDED_DBS[$db]:-0}" == "1" ]]; then
    DB_ACTION["$db"]="exclude"
    TO_EXCLUDE=$(( TO_EXCLUDE + 1 ))
  elif [[ "${DST_DB_EXISTS[$db]:-0}" == "1" ]]; then
    n="${DST_DB_TABLES[$db]:-0}"
    if (( n > 0 )); then
      DB_ACTION["$db"]="skip"
      TO_SKIP=$(( TO_SKIP + 1 ))
    else
      DB_ACTION["$db"]="restore"
      TO_RESTORE=$(( TO_RESTORE + 1 ))
    fi
  else
    DB_ACTION["$db"]="create"
    TO_CREATE=$(( TO_CREATE + 1 ))
  fi
done

declare -A ROLE_ACTION  # present | missing
ROLES_MISSING=0
ROLES_BLOCKING=0

for role in "${SRC_ROLES[@]}"; do
  if [[ "${DST_ROLE_EXISTS[$role]:-0}" == "1" ]]; then
    ROLE_ACTION["$role"]="present"
  else
    ROLE_ACTION["$role"]="missing"
    ROLES_MISSING=$(( ROLES_MISSING + 1 ))
  fi
done

# Total size being added to CNPG (create/restore/drop_restore databases)
MIGRATE_DBS=()
for db in "${DB_LIST[@]}"; do
  [[ "${DB_ACTION[$db]}" == "create" || "${DB_ACTION[$db]}" == "restore" || "${DB_ACTION[$db]}" == "drop_restore" ]] && MIGRATE_DBS+=("'$db'")
done
if [[ ${#MIGRATE_DBS[@]} -gt 0 ]]; then
  db_list=$(IFS=','; echo "${MIGRATE_DBS[*]}")
  TOTAL_SIZE=$(csql -c "
    SELECT pg_size_pretty(sum(pg_database_size(datname)))
    FROM pg_database WHERE datname IN ($db_list)
  " 2>/dev/null || echo "?")
else
  TOTAL_SIZE="0 bytes"
fi

# Which missing roles are blockers (they own a database being migrated, not excluded)
declare -A ROLE_BLOCKS_DB
for db in "${DB_LIST[@]}"; do
  if [[ "${DB_ACTION[$db]}" == "create" || "${DB_ACTION[$db]}" == "restore" ]]; then
    owner="${DB_OWNER[$db]}"
    if [[ "${ROLE_ACTION[$owner]:-present}" == "missing" ]]; then
      ROLE_BLOCKS_DB["$owner"]="${ROLE_BLOCKS_DB[$owner]:+${ROLE_BLOCKS_DB[$owner]}, }$db"
      ROLES_BLOCKING=$(( ROLES_BLOCKING + 1 ))
    fi
  fi
done

# ── print plan ───────────────────────────────────────────────────────────────────

section "Migration Plan"

echo ""
printf '%s  Databases%s  (%s+%s create  %s~%s restore into existing  %s=%s skip  - exclude)\n' \
  "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET"
echo ""

EXT_WARN=false
for db in "${DB_LIST[@]}"; do
  owner="${DB_OWNER[$db]}"
  size="${DB_SIZE[$db]:-?}"
  tables="${DB_TABLES[$db]:-?}"
  exts="${DB_EXTENSIONS[$db]:-}"
  action="${DB_ACTION[$db]}"
  dst_tables="${DST_DB_TABLES[$db]:-0}"

  case "$action" in
    create)
      printf '  %s+%s %-22s  owner=%-18s  size=%-10s  tables=%s\n' \
        "$C_GREEN" "$C_RESET" "$db" "$owner" "$size" "$tables"
      ;;
    restore)
      printf '  %s~%s %-22s  owner=%-18s  size=%-10s  tables=%-6s  %s(CNPG has 0 tables — will restore)%s\n' \
        "$C_CYAN" "$C_RESET" "$db" "$owner" "$size" "$tables" "$C_DIM" "$C_RESET"
      ;;
    skip)
      printf '  %s=%s %-22s  owner=%-18s  size=%-10s  %sSKIP: CNPG already has %s tables%s\n' \
        "$C_DIM" "$C_RESET" "$db" "$owner" "$size" "$C_YELLOW" "$dst_tables" "$C_RESET"
      continue
      ;;
    exclude)
      printf '  %s- %-22s  owner=%-18s  size=%-10s  excluded%s\n' \
        "$C_DIM" "$db" "$owner" "$size" "$C_RESET"
      continue
      ;;
  esac

  if [[ -n "$exts" ]]; then
    IFS=',' read -ra exts_arr <<< "$exts"
    for ext in "${exts_arr[@]}"; do
      [[ -z "$ext" ]] && continue
      if ext_available "$ext"; then
        printf '      %sext: %-22s %s%s available%s\n' "$C_DIM" "$ext" "$C_GREEN" "$SYM_OK" "$C_RESET"
      else
        printf '      %sext: %-22s %s%s NOT available on CNPG%s\n' "$C_DIM" "$ext" "$C_RED" "$SYM_FAIL" "$C_RESET"
        EXT_WARN=true
      fi
    done
  fi
done

echo ""
printf '%s  Roles%s  (%s+%s missing on CNPG  %s=%s present)\n' \
  "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" "$C_DIM" "$C_RESET"
echo ""

ROLE_WARN=false
for role in "${SRC_ROLES[@]}"; do
  action="${ROLE_ACTION[$role]}"
  attrs="${ROLE_LOGIN[$role]:-?}, ${ROLE_SUPER[$role]:-?}"
  [[ "${ROLE_REPLICATION[$role]:-NOREPLICATION}" == "REPLICATION" ]] && attrs="$attrs, REPLICATION"
  [[ "${ROLE_CREATEROLE[$role]:-NOCREATEROLE}"  == "CREATEROLE"  ]] && attrs="$attrs, CREATEROLE"
  [[ "${ROLE_CREATEDB[$role]:-NOCREATEDB}"      == "CREATEDB"    ]] && attrs="$attrs, CREATEDB"

  if [[ "$action" == "present" ]]; then
    printf '  %s= %-22s  (%s)%s\n' "$C_DIM" "$role" "$attrs" "$C_RESET"
  elif [[ -v "ROLE_BLOCKS_DB[$role]" ]]; then
    printf '  %s+%s %s%-22s%s  (%s)  %s%s BLOCKER: owns database(s): %s%s\n' \
      "$C_RED" "$C_RESET" "$C_RED" "$role" "$C_RESET" "$attrs" "$C_RED" "$SYM_FAIL" "${ROLE_BLOCKS_DB[$role]}" "$C_RESET"
    ROLE_WARN=true
  else
    printf '  %s+%s %s%-22s%s  (%s)  %s%s missing — add to CNPG managed roles%s\n' \
      "$C_GREEN" "$C_RESET" "$C_YELLOW" "$role" "$C_RESET" "$attrs" "$C_YELLOW" "$SYM_WARN" "$C_RESET"
    ROLE_WARN=true
  fi
done

# CNPG-only roles (informational)
for role in "${DST_ROLES[@]}"; do
  if [[ ! -v "ROLE_ACTION[$role]" ]]; then
    printf '  %s? %-22s  (CNPG-only — not in source)%s\n' "$C_DIM" "$role" "$C_RESET"
  fi
done

# Summary header
echo ""
printf '%s%s%s\n' "$C_BOLD" '══════════════════════════════════════════════' "$C_RESET"
if (( TO_EXCLUDE > 0 )); then
  printf ' %sPlan:%s %s to create, %s to restore, %s to skip, %s excluded  |  %s+%s %s\n' \
    "$C_BOLD" "$C_RESET" "$TO_CREATE" "$TO_RESTORE" "$TO_SKIP" "$TO_EXCLUDE" "$C_GREEN" "$C_RESET" "$TOTAL_SIZE"
else
  printf ' %sPlan:%s %s to create, %s to restore, %s to skip  |  %s+%s %s\n' \
    "$C_BOLD" "$C_RESET" "$TO_CREATE" "$TO_RESTORE" "$TO_SKIP" "$C_GREEN" "$C_RESET" "$TOTAL_SIZE"
fi
if (( ROLES_BLOCKING > 0 )); then
  printf ' %s%s %d role(s) are BLOCKERS — migration will stall until they exist on CNPG%s\n' \
    "$C_RED" "$SYM_FAIL" "$ROLES_BLOCKING" "$C_RESET"
fi
if $ROLE_WARN && (( ROLES_MISSING > ROLES_BLOCKING )); then
  printf ' %s%s  %d role(s) missing on CNPG (no database owned — informational)%s\n' \
    "$C_YELLOW" "$SYM_WARN" "$(( ROLES_MISSING - ROLES_BLOCKING ))" "$C_RESET"
fi
if $EXT_WARN; then
  printf ' %s%s  Some extensions are NOT available on CNPG — migration may fail%s\n' \
    "$C_RED" "$SYM_WARN" "$C_RESET"
fi
printf '%s%s%s\n' "$C_BOLD" '══════════════════════════════════════════════' "$C_RESET"
echo ""

# ── verify one database ──────────────────────────────────────────────────────────

verify_db() {
  local db="$1"
  local matched=0 mismatches=0 errs=0
  local src_f dst_f
  src_f=$(mktemp) dst_f=$(mktemp)
  trap 'rm -f "$src_f" "$dst_f"' RETURN

  section "Verifying: $db"

  local tables=()
  while IFS='|' read -r schema tbl; do
    [[ -z "$schema" || -z "$tbl" ]] && continue
    tables+=("${schema}|${tbl}")
  done < <(csql -d "$db" -c "
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog','information_schema',
        '_timescaledb_internal','_timescaledb_catalog','_timescaledb_functions'
      )
    ORDER BY table_schema, table_name
  " 2>/dev/null) || { warn "$db — failed to list source tables"; return 1; }

  if [[ ${#tables[@]} -eq 0 ]]; then
    warn "$db — no tables found on source"
    return 0
  fi

  for entry in "${tables[@]}"; do
    local schema="${entry%%|*}"
    local tbl="${entry#*|}"
    local label="$schema.$tbl"
    # count + order-independent sum-of-hashes: detects any bit-level difference
    local sql="SELECT count(*)::text||':'||COALESCE(sum(hashtext(t::text)::bigint)::text,'0') FROM \"${schema}\".\"${tbl}\" t"

    # Run both queries in parallel — only the hash value crosses the wire
    local src dst src_pid dst_pid
    csql -d "$db" -c "$sql" > "$src_f" 2>/dev/null & src_pid=$!
    nsql -d "$db" -c "$sql" > "$dst_f" 2>/dev/null & dst_pid=$!
    wait "$src_pid" || true
    wait "$dst_pid" || true
    src=$(<"$src_f") || src="ERR"
    dst=$(<"$dst_f") || dst="ERR"
    : > "$src_f"; : > "$dst_f"
    [[ -z "$src" ]] && src="ERR"
    [[ -z "$dst" ]] && dst="ERR"

    if [[ "$src" == "ERR" || "$dst" == "ERR" ]]; then
      printf '  %s? %-50s  (hash error)%s\n' "$C_YELLOW" "$label" "$C_RESET"
      errs=$(( errs + 1 ))
    elif [[ "$src" != "$dst" ]]; then
      local src_rows="${src%%:*}" dst_rows="${dst%%:*}"
      local src_hash="${src#*:}"  dst_hash="${dst#*:}"
      printf '  %s%s %-50s  rows src=%-8s dst=%-8s  hash src=%-22s dst=%s%s\n' \
        "$C_RED" "$SYM_FAIL" "$label" "$src_rows" "$dst_rows" "$src_hash" "$dst_hash" "$C_RESET"
      mismatches=$(( mismatches + 1 ))
    else
      local rows="${src%%:*}"
      printf '  %s%s %-50s  rows=%-8s  hash=%s%s\n' \
        "$C_GREEN" "$SYM_OK" "$label" "$rows" "${src#*:}" "$C_RESET"
      matched=$(( matched + 1 ))
    fi
  done

  local total=$(( matched + mismatches + errs ))
  echo ""
  if (( mismatches == 0 && errs == 0 )); then
    ok "$db — all $total table(s) match"
  else
    warn "$db — $mismatches mismatch(es), $errs error(s) out of $total table(s)"
  fi
  return $(( mismatches > 0 ? 1 : 0 ))
}

# ── dry-run / verify-only exits ──────────────────────────────────────────────────

# Dry-run: stop here
if $DRY_RUN; then
  printf '%sDry-run mode — no changes will be made.%s\n' "$C_YELLOW" "$C_RESET"
  exit 0
fi

# Verify-only: skip migration and compare checksums
if $VERIFY_ONLY; then
  section "Verifying data integrity"
  log "Comparing per-table row checksums between source and CNPG..."
  echo ""
  VERIFY_FAILED=()
  for db in "${DB_LIST[@]}"; do
    [[ "${EXCLUDED_DBS[$db]:-0}" == "1" ]] && continue
    if [[ "${DST_DB_EXISTS[$db]:-0}" != "1" ]]; then
      warn "$db — not present on CNPG, skipping"
      continue
    fi
    if ! verify_db "$db"; then
      VERIFY_FAILED+=("$db")
    fi
  done
  echo ""
  if (( ${#VERIFY_FAILED[@]} > 0 )); then
    die "Verification FAILED for: ${VERIFY_FAILED[*]}"
  fi
  ok "All databases verified successfully"
  exit 0
fi

# Interactive selection
if ! $AUTO_APPROVE; then
  command -v gum &>/dev/null \
    || die "gum is required for interactive mode — install it or use --auto-approve"

  if $ROLE_WARN; then
    warn "Some roles are missing on CNPG. Databases owned by missing roles may fail."
    warn "Add them to the CNPG Cluster spec's managedRoles before proceeding."
    echo ""
  fi
  if $EXT_WARN; then
    warn "Some extensions are unavailable on CNPG. Review the plan before proceeding."
    echo ""
  fi

  # ── Step 1: select databases to migrate ───────────────────────────────────────

  GUM_ITEMS=()
  GUM_DBS=()
  for db in "${DB_LIST[@]}"; do
    [[ "${EXCLUDED_DBS[$db]:-0}" == "1" ]] && continue
    action="${DB_ACTION[$db]}"
    size="${DB_SIZE[$db]:-?}"
    ntables="${DB_TABLES[$db]:-?}"
    dst="${DST_DB_TABLES[$db]:-0}"
    case "$action" in
      create)  tag="new" ;;
      restore) tag="restore  (CNPG empty)" ;;
      skip)    tag="skip  — CNPG has $dst tables" ;;
    esac
    GUM_ITEMS+=("$(printf '%-22s  %-10s  %-6s src tables  %s' "$db" "$size" "$ntables" "$tag")")
    GUM_DBS+=("$db")
  done

  if [[ ${#GUM_ITEMS[@]} -eq 0 ]]; then
    log "Nothing to migrate."
    exit 0
  fi

  selected_raw=$(printf '%s\n' "${GUM_ITEMS[@]}" | \
    gum choose --no-limit --header "Select databases to migrate") || true

  if [[ -z "$selected_raw" ]]; then
    printf '%sCancelled.%s\n' "$C_YELLOW" "$C_RESET"
    exit 0
  fi

  declare -A SEL_DBS
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    for i in "${!GUM_ITEMS[@]}"; do
      if [[ "${GUM_ITEMS[$i]}" == "$line" ]]; then
        SEL_DBS["${GUM_DBS[$i]}"]=1
        break
      fi
    done
  done <<< "$selected_raw"

  # Mark unselected databases as excluded
  for db in "${DB_LIST[@]}"; do
    [[ "${EXCLUDED_DBS[$db]:-0}" == "1" ]] && continue
    [[ "${SEL_DBS[$db]:-0}" == "1" ]] || DB_ACTION["$db"]="exclude"
  done

  # ── Step 2: pick which skip-databases to DROP first ───────────────────────────

  DROP_ITEMS=()
  DROP_DBS=()
  for db in "${DB_LIST[@]}"; do
    [[ "${SEL_DBS[$db]:-0}" == "1" && "${DB_ACTION[$db]}" == "skip" ]] || continue
    dst="${DST_DB_TABLES[$db]:-0}"
    DROP_ITEMS+=("$(printf '%-22s  %s tables on CNPG' "$db" "$dst")")
    DROP_DBS+=("$db")
  done

  if [[ ${#DROP_ITEMS[@]} -gt 0 ]]; then
    drop_raw=$(printf '%s\n' "${DROP_ITEMS[@]}" | \
      gum choose --no-limit \
        --header "⚠ DROP before migrating? (these have existing data on CNPG)") || true

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      for i in "${!DROP_ITEMS[@]}"; do
        if [[ "${DROP_ITEMS[$i]}" == "$line" ]]; then
          DB_ACTION["${DROP_DBS[$i]}"]=drop_restore
          break
        fi
      done
    done <<< "$drop_raw"
  fi

  echo ""
fi

# ── wait for managed roles ───────────────────────────────────────────────────────

section "Waiting for managed roles"

NEEDED_ROLES=()
for db in "${DB_LIST[@]}"; do
  [[ "${DB_ACTION[$db]}" == "create" || "${DB_ACTION[$db]}" == "restore" || "${DB_ACTION[$db]}" == "drop_restore" ]] && NEEDED_ROLES+=("${DB_OWNER[$db]}")
done
mapfile -t NEEDED_ROLES < <(printf '%s\n' "${NEEDED_ROLES[@]+"${NEEDED_ROLES[@]}"}" | sort -u)

if [[ ${#NEEDED_ROLES[@]} -gt 0 ]]; then
  log "Roles required: ${NEEDED_ROLES[*]}"
  for role in "${NEEDED_ROLES[@]}"; do
    [[ -z "$role" ]] && continue
    log "  waiting for role '$role'..."
    for attempt in $(seq 1 30); do
      found=$(kubectl exec -n "$NS" "$CNPG_POD" -c postgres -- \
        psql -U postgres -tAq -c "SELECT 1 FROM pg_roles WHERE rolname='$role'" 2>/dev/null || true)
      if [[ "$found" == "1" ]]; then
        log "    $SYM_OK '$role' present (attempt $attempt)"
        break
      fi
      if (( attempt == 30 )); then
        kubectl get cluster postgres -n "$NS" -o jsonpath='{.status}' | \
          python3 -m json.tool 2>/dev/null || true
        die "role '$role' still missing after 30s — check CNPG Cluster managedRoles events"
      fi
      sleep 1
    done
  done
  ok "All required roles present"
else
  log "No roles to wait for"
fi

# ── migrate one database ─────────────────────────────────────────────────────────

migrate() {
  local db="$1"
  local owner="${DB_OWNER[$db]}"
  local action="${DB_ACTION[$db]}"
  local db_start
  db_start=$(date +%s)

  section "Migrating: $db  (owner: $owner)"

  if [[ "$action" == "exclude" ]]; then
    log "$db — excluded"
    return 0
  fi
  if [[ "$action" == "skip" ]]; then
    warn "$db — SKIP: CNPG already has ${DST_DB_TABLES[$db]:-?} tables; drop the database to re-migrate"
    return 0
  fi

  if [[ "$action" == "drop_restore" ]]; then
    warn "$db — dropping existing CNPG database before restore..."
    nsql -c "DROP DATABASE \"$db\";" || die "failed to DROP DATABASE '$db'"
    ok "$db dropped"
    nsql -c "CREATE DATABASE \"$db\" OWNER \"$owner\";" || die "failed to recreate '$db'"
    ok "Database '$db' recreated"
    action="restore"
  elif [[ "$action" == "restore" ]]; then
    log "$db exists on CNPG but is empty — restoring into it"
  else
    log "Creating database '$db' with owner '$owner'..."
    nsql -c "CREATE DATABASE \"$db\" OWNER \"$owner\";" \
      || die "failed to CREATE DATABASE '$db'"
    ok "Database '$db' created"
  fi

  log "Source — size: ${DB_SIZE[$db]:-?}  tables: ${DB_TABLES[$db]:-?}"

  # Pre-create extensions to avoid version mismatch errors during restore.
  # Extensions requiring shared_preload_libraries are skipped — they can't be
  # created manually and their restore errors are filtered below.
  # timescaledb is installed first — its dump includes timescaledb_pre_restore()
  # and timescaledb_post_restore() calls that require the extension to be present.
  if [[ -n "${DB_EXTENSIONS[$db]:-}" ]]; then
    log "Installing extensions..."
    IFS=',' read -ra exts_arr <<< "${DB_EXTENSIONS[$db]}"

    # Pass 1: timescaledb must be installed before anything else, at the source
    # version so catalog schemas match during restore. After restore we upgrade.
    for ext in "${exts_arr[@]}"; do
      [[ "$ext" == "timescaledb" ]] || continue
      log "  + timescaledb (required before restore)"
      local src_tsdb_ver tsdb_ver
      src_tsdb_ver=$(csql -d "$db" -c "SELECT extversion FROM pg_extension WHERE extname='timescaledb'" 2>/dev/null || echo "")
      # Prefer the source version; fall back to highest available
      if [[ -n "$src_tsdb_ver" ]]; then
        local avail
        avail=$(nsql -c "SELECT 1 FROM pg_available_extension_versions WHERE name='timescaledb' AND version='$src_tsdb_ver'" 2>/dev/null || echo "")
        [[ -n "$avail" ]] && tsdb_ver="$src_tsdb_ver"
      fi
      if [[ -z "$tsdb_ver" ]]; then
        tsdb_ver=$(nsql -c "SELECT max(version) FROM pg_available_extension_versions WHERE name='timescaledb'" 2>/dev/null || echo "")
        [[ -n "$src_tsdb_ver" ]] && warn "  source timescaledb $src_tsdb_ver not available on target — installing $tsdb_ver (schema diffs may cause errors)"
      fi
      if [[ -z "$tsdb_ver" ]]; then
        die "timescaledb is not available on CNPG cluster — check the cluster image"
      fi
      log "    installing timescaledb version $tsdb_ver"
      nsql -d "$db" -c "CREATE EXTENSION IF NOT EXISTS timescaledb WITH VERSION '$tsdb_ver' CASCADE;" > /dev/null 2>&1 \
        || die "failed to pre-install timescaledb $tsdb_ver in '$db' — cannot restore"
    done

    # Pass 2: remaining extensions
    for ext in "${exts_arr[@]}"; do
      [[ -z "$ext" || "$ext" == "timescaledb" ]] && continue
      local is_preload=false
      for pe in "${PRELOAD_EXTENSIONS[@]}"; do
        [[ "$ext" == "$pe" ]] && is_preload=true && break
      done
      if $is_preload; then
        log "  ~ $ext (skipped — requires shared_preload_libraries)"
        continue
      fi
      log "  + $ext"
      if ! nsql -d "$db" -c "CREATE EXTENSION IF NOT EXISTS \"$ext\" CASCADE;" > /dev/null 2>&1; then
        warn "  failed to pre-create '$ext' — pg_restore may error on it"
      fi
    done
  fi

  # For TimescaleDB: disable internal triggers/circular-FK constraints before restore
  local is_timescaledb=false
  for ext in "${exts_arr[@]-}"; do
    [[ "$ext" == "timescaledb" ]] && is_timescaledb=true && break
  done

  if $is_timescaledb; then
    log "Calling timescaledb_pre_restore()..."
    nsql -d "$db" -c "SELECT timescaledb_pre_restore();" > /dev/null \
      || warn "timescaledb_pre_restore() failed — circular FK errors may occur"
  fi

  # Stream dump → restore
  log "Streaming pg_dump | pg_restore..."

  local err_file
  err_file=$(mktemp /tmp/pg_restore_err.XXXXXX)
  trap 'rm -f "$err_file"' RETURN

  set +e
  kubectl exec -n "$NS" "$CRUNCHY_POD" -c database -- \
    pg_dump -U postgres -Fc -d "$db" \
  | kubectl exec -i -n "$NS" "$CNPG_POD" -c postgres -- \
    pg_restore -U postgres -d "$db" --no-acl \
    2>"$err_file"
  local pipe_status=("${PIPESTATUS[@]}")
  set -e

  local dump_rc="${pipe_status[0]}"
  local restore_rc="${pipe_status[1]}"

  if $is_timescaledb; then
    log "Calling timescaledb_post_restore()..."
    nsql -d "$db" -c "SELECT timescaledb_post_restore();" > /dev/null \
      || warn "timescaledb_post_restore() failed — run manually: SELECT timescaledb_post_restore();"
    # Upgrade to the highest available version after restore
    local installed_ver latest_ver
    installed_ver=$(nsql -d "$db" -c "SELECT extversion FROM pg_extension WHERE extname='timescaledb'" 2>/dev/null || echo "")
    latest_ver=$(nsql -c "SELECT max(version) FROM pg_available_extension_versions WHERE name='timescaledb'" 2>/dev/null || echo "")
    if [[ -n "$latest_ver" && -n "$installed_ver" && "$installed_ver" != "$latest_ver" ]]; then
      log "  upgrading timescaledb $installed_ver → $latest_ver..."
      nsql -d "$db" -c "ALTER EXTENSION timescaledb UPDATE TO '$latest_ver';" > /dev/null 2>&1 \
        || warn "timescaledb upgrade failed — run manually: ALTER EXTENSION timescaledb UPDATE TO '$latest_ver';"
    fi
  fi

  if (( dump_rc != 0 )); then
    cat "$err_file" >&2
    die "pg_dump failed for '$db' (exit $dump_rc)"
  fi

  if (( restore_rc != 0 )); then
    # Escape extension names for use as literal strings in a grep alternation.
    local preload_pat
    preload_pat=$(printf '%s\n' "${PRELOAD_EXTENSIONS[@]}" \
      | sed 's/[.[\*^$]/\\&/g' | paste -sd'|')
    # Only examine the actual error lines — CONTEXT/Command continuation lines
    # are noise and may not contain the extension name.
    local real_errors
    real_errors=$(grep '^pg_restore: error:' "$err_file" \
      | grep -Ev "already exists|${preload_pat}") || true
    if [[ -n "$real_errors" ]]; then
      cat "$err_file" >&2
      die "pg_restore failed for '$db' (exit $restore_rc)"
    fi
    warn "$db — pg_restore exited $restore_rc but only ignorable warnings found"
  fi

  if [[ -s "$err_file" ]]; then
    local wc
    wc=$(grep -c 'already exists' "$err_file" 2>/dev/null || echo 0)
    log "Suppressed $wc 'already exists' warning(s) from extension objects"
  fi

  # Sanity check: table counts
  local src_tables dst_tables
  src_tables=$(csql -d "$db" -c "
    SELECT count(*) FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog','information_schema')" 2>/dev/null || echo 0)
  dst_tables=$(nsql -d "$db" -c "
    SELECT count(*) FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog','information_schema')" 2>/dev/null || echo 0)

  log "Tables — source: $src_tables  target: $dst_tables"

  if (( dst_tables == 0 )); then
    die "no tables in '$db' on CNPG after restore — something went wrong"
  fi
  if (( dst_tables < src_tables )); then
    warn "$db — target has fewer tables than source ($dst_tables < $src_tables) — inspect manually"
  fi

  local db_elapsed=$(( $(date +%s) - db_start ))
  ok "$db migrated in ${db_elapsed}s"
}

# ── run all migrations ───────────────────────────────────────────────────────────

section "Running migrations"

FAILED=()

for db in "${DB_LIST[@]}"; do
  if ! migrate "$db"; then
    FAILED+=("$db")
    warn "Migration failed for '$db' — continuing with remaining databases"
  fi
done

# ── summary ──────────────────────────────────────────────────────────────────────

section "Summary  (elapsed: $(elapsed))"

nsql -c "\l" 2>/dev/null || warn "could not list databases on CNPG"

echo ""
log "Results:"
for db in "${DB_LIST[@]}"; do
  action="${DB_ACTION[$db]}"
  if [[ "$action" == "exclude" ]]; then
    printf '  %s- %-22s excluded%s\n' "$C_DIM" "$db" "$C_RESET"
  elif [[ "$action" == "skip" ]]; then
    printf '  %s= %-22s skipped%s\n' "$C_DIM" "$db" "$C_RESET"
  elif printf '%s\n' "${FAILED[@]+"${FAILED[@]}"}" | grep -qx "$db"; then
    printf '  %s%s %-22s FAILED%s\n' "$C_RED" "$SYM_FAIL" "$db" "$C_RESET"
  elif [[ "$action" == "drop_restore" ]]; then
    printf '  %s%s %-22s ok (dropped + restored)%s\n' "$C_GREEN" "$SYM_OK" "$db" "$C_RESET"
  else
    printf '  %s%s %-22s ok%s\n' "$C_GREEN" "$SYM_OK" "$db" "$C_RESET"
  fi
done

if (( ${#FAILED[@]} > 0 )); then
  echo ""
  die "The following databases FAILED: ${FAILED[*]}"
fi

echo ""
ok "All ${#DB_LIST[@]} database(s) processed successfully."
log ""
log "Next steps:"
log "  1. Verify app connectivity through the CNPG pooler"
log "  2. Spot-check critical tables: row counts, recent timestamps, etc."
log "  3. Once satisfied, switch apps to the CNPG connection string"
log "  4. Decommission crunchy-postgres"
