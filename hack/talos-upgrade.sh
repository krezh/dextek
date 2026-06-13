#!/usr/bin/env bash
set -euo pipefail

# Colors & text (guarded so output stays clean when not attached to a tty)
if [[ -t 1 ]]; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  DIM=$(tput dim)
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
else
  RED="" GREEN="" BLUE="" MAGENTA="" CYAN="" DIM="" BOLD="" RESET=""
fi

# Defaults
IMAGE="factory.talos.dev/metal-installer"
NEW_VERSION=""
SCHEMA_ID=""           # optional override; empty => keep each node's current schematic
NODES=()
FORCE=false
HEALTH_TIMEOUT="10m"   # talosctl health wait
CEPH_TIMEOUT=900       # seconds to wait for HEALTH_OK
VOLSYNC_TIMEOUT=900    # seconds to wait for syncs to settle
POLL_INTERVAL=15

shutdown() { tput cnorm 2>/dev/null || true; }
trap shutdown EXIT

# Wrap talosctl to drop noisy stderr lines (version-skew warning and the
# "unavailable, retrying..." reboot spam) while preserving real errors and the
# exit code.
talosctl() {
  command talosctl "$@" 2> >(grep -vE 'is older than client version|unavailable, retrying' >&2)
}

# --- output helpers ----------------------------------------------------------

RULE="────────────────────────────────────────────────────────────"

hr()      { printf '%s%s%s\n' "$DIM" "$RULE" "$RESET"; }
step()    { printf '  %s→%s %s\n' "$CYAN" "$RESET" "$*"; }
ok()      { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
fail()    { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; }
info()    { printf '  %s•%s %s\n' "$DIM" "$RESET" "$*"; }
err()     { printf '%s✗ ERROR:%s %s\n' "${BOLD}${RED}" "$RESET" "$*" >&2; }

banner() {
  local shorts joined
  shorts=("${NODES[@]%%.*}")
  printf -v joined '%s, ' "${shorts[@]}"; joined=${joined%, }
  printf '\n%s%s Talos upgrade %s\n' "$BOLD" "$BLUE" "$RESET"
  hr
  printf '  %-10s %s%s%s\n' "version"   "$BOLD" "$NEW_VERSION" "$RESET"
  printf '  %-10s %s\n' "schematic" "${SCHEMA_ID:+${SCHEMA_ID:0:16}… (override)}"
  printf '  %-10s %s %s(%d)%s\n' "nodes" "$joined" "$DIM" "${#NODES[@]}" "$RESET"
  hr
  printf '\n'
}

node_header() {
  local node=$1 cur_v=$2 cur_s=$3 tgt_v=$4 tgt_s=$5
  printf '%s%s▶ %s%s\n' "$BOLD" "$MAGENTA" "$node" "$RESET"
  printf '  %sv%s%s %s(%s)%s  %s→%s  %s%s%s %s(%s)%s\n' \
    "$DIM" "$cur_v" "$RESET" "$DIM" "${cur_s:0:12}" "$RESET" \
    "$CYAN" "$RESET" \
    "$BOLD" "$tgt_v" "$RESET" "$DIM" "${tgt_s:0:12}" "$RESET"
}

usage() {
  cat >&2 <<EOF
${BOLD}Usage:${RESET} $0 -n <node1,node2> -v <version> [-s <schematic>] [-f] [-A]
  -n  Comma-separated list of nodes (required unless -A)
  -v  Target Talos version, e.g. 1.13.4 (required)
  -s  Schematic ID override (default: keep each node's current schematic)
  -f  Force, even if the node already runs the target image
  -A  All nodes
  -h  Help

${BOLD}Examples:${RESET}
  $0 -A -v 1.13.4
  $0 -n ms01-01 -v 1.13.2 -s dbc77981... -f   # swap schematic, same version
EOF
  exit 1
}

while getopts "hn:v:s:fFA" opt; do
  case $opt in
  h) usage ;;
  n) IFS=',' read -r -a NODES <<<"$OPTARG" ;;
  v) NEW_VERSION="v${OPTARG#v}" ;;
  s) SCHEMA_ID="$OPTARG" ;;
  f | F) FORCE=true ;;
  A) IFS=$'\n' read -r -d '' -a NODES < <(talosctl get nodenames -o json | jq -r .node && printf '\0') ;;
  \?) err "Invalid option: -$OPTARG"; usage ;;
  esac
done

[[ -n "$NEW_VERSION" ]] || { err "-v <version> is required."; usage; }
[[ ${#NODES[@]} -gt 0 ]] || { err "No nodes specified. Use -n or -A."; usage; }

# --- helpers -----------------------------------------------------------------

# Poll a command until it succeeds or the timeout elapses.
poll() {
  local timeout=$1 interval=$2; shift 2
  local end=$((SECONDS + timeout))
  until "$@"; do
    ((SECONDS >= end)) && return 1
    sleep "$interval"
  done
}

node_version()   { talosctl -n "$1" get version -o json | jq -r '.spec.version' | sed 's/^v//'; }
node_schematic() { talosctl -n "$1" get nodestatus -o json | jq -r '.spec.annotations["extensions.talos.dev/schematic"] // empty'; }

ceph_present()    { kubectl get crd cephclusters.ceph.rook.io >/dev/null 2>&1; }
volsync_present() { kubectl get crd replicationsources.volsync.backube >/dev/null 2>&1; }

ceph_ok() {
  local health
  health=$(kubectl get cephcluster -A -o jsonpath='{range .items[*]}{.status.ceph.health}{"\n"}{end}' 2>/dev/null) || return 1
  [[ -n "$health" ]] && ! grep -qv '^HEALTH_OK$' <<<"$health"
}

volsync_quiet() {
  local syncing
  syncing=$(kubectl get replicationsource -A -o json 2>/dev/null \
    | jq '[.items[].status.conditions[]? | select(.type=="Synchronizing" and .status=="True")] | length') || return 1
  [[ "$syncing" == "0" ]]
}

# Run all applicable health gates in parallel and wait for every one.
wait_healthy() {
  local node=$1
  local -a pids=() names=()

  talosctl --nodes "$node" health --wait-timeout="$HEALTH_TIMEOUT" --server=false >/dev/null 2>&1 &
  pids+=($!); names+=("talos health")

  if ceph_present; then
    poll "$CEPH_TIMEOUT" "$POLL_INTERVAL" ceph_ok &
    pids+=($!); names+=("ceph HEALTH_OK")
  fi

  if volsync_present; then
    poll "$VOLSYNC_TIMEOUT" "$POLL_INTERVAL" volsync_quiet &
    pids+=($!); names+=("volsync idle")
  fi

  local rc=0 i
  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
      ok "${names[$i]}"
    else
      fail "${names[$i]}"
      rc=1
    fi
  done
  return $rc
}

# --- main --------------------------------------------------------------------

banner

for node in "${NODES[@]}"; do
  node="${node%%.*}"  # short name; talosctl/kubectl resolve it

  if ! talosctl get nodenames -n "$node" >/dev/null 2>&1; then
    err "Node \"$node\" does not exist"; exit 1
  fi

  current_version=$(node_version "$node")
  current_schematic=$(node_schematic "$node")
  target_schematic="${SCHEMA_ID:-$current_schematic}"
  target_image="$IMAGE/$target_schematic:$NEW_VERSION"

  node_header "$node" "$current_version" "$current_schematic" "${NEW_VERSION#v}" "$target_schematic"

  if [[ "v$current_version" == "$NEW_VERSION" && "$current_schematic" == "$target_schematic" ]]; then
    if [[ "$FORCE" == false ]]; then
      info "already on target image — skipping (use -f to force)"
      printf '\n'
      continue
    fi
    info "already on target image — forcing"
  fi

  start=$SECONDS
  step "upgrading via ${DIM}${target_image}${RESET}"
  step "pulling image & rebooting — this takes a few minutes${DIM}…${RESET}"
  if ! talosctl upgrade -n "$node" --image "$target_image" >/dev/null; then
    err "upgrade of $node failed"; exit 1
  fi

  step "waiting for health gates"
  if ! wait_healthy "$node"; then
    err "aborting: $node did not return healthy"; exit 1
  fi

  current_version=$(node_version "$node")
  printf '  %s%s✓ done%s %sv%s · %s · %ds%s\n\n' \
    "$BOLD" "$GREEN" "$RESET" "$DIM" "$current_version" "${target_schematic:0:12}" "$((SECONDS - start))" "$RESET"
done

hr
printf '%s%s✓ all nodes complete%s\n\n' "$BOLD" "$GREEN" "$RESET"
