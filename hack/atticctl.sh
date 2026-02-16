#!/usr/bin/env bash

# Colors & Text
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)

# Default Variables
NAMESPACE="default"

shutdown() {
  tput cnorm # reset cursor
}

trap shutdown EXIT

usage() {
  echo -e "Usage: $0 [-n <namespace>] <command> [subcommand] [flags]"
  echo -e ""
  echo -e "Global Flags:"
  echo -e "  -n <namespace>  Kubernetes namespace (default: default)"
  echo -e ""
  echo -e "Commands:"
  echo -e "  create token admin --validity <duration>"
  echo -e "      Generate a token with all permissions on all caches (*)"
  echo -e ""
  echo -e "  create token ci --validity <duration> --cache <pattern>"
  echo -e "      Generate a token with push+pull on the specified cache"
  echo -e ""
  echo -e "  create token <subject> --validity <duration> [permission flags]"
  echo -e "      Generate a token with explicit per-permission cache patterns"
  echo -e "      --pull <pattern>                     Grant pull on matching caches"
  echo -e "      --push <pattern>                     Grant push on matching caches"
  echo -e "      --delete <pattern>                   Grant delete on matching caches"
  echo -e "      --create-cache <pattern>             Grant cache creation"
  echo -e "      --configure-cache <pattern>          Grant cache configuration"
  echo -e "      --configure-cache-retention <pattern>  Grant retention configuration"
  echo -e "      --destroy-cache <pattern>            Grant cache destruction"
  echo -e ""
  echo -e "  exec"
  echo -e "      Open an interactive shell in the attic pod"
  echo -e ""
  echo -e "Examples:"
  echo -e "  $0 create token admin --validity 1y"
  echo -e "  $0 create token ci --validity 30d --cache nixpkgs"
  echo -e "  $0 create token myuser --validity 30d --pull \"*\" --push nixpkgs"
  echo -e "  $0 exec"
  echo -e "  $0 -n mynamespace exec"
  exit 1
}

get_pod() {
  local namespace="$1"
  kubectl get pods -n "$namespace" -l app.kubernetes.io/name=attic -o jsonpath='{.items[0].metadata.name}'
}

cmd_create_token_admin() {
  local namespace="$1"
  shift

  local validity=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --validity)
      validity="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage
      ;;
    esac
  done

  if [[ -z "$validity" ]]; then
    echo "Error: --validity is required." >&2
    usage
  fi

  local pod
  pod=$(get_pod "$namespace")
  if [[ -z "$pod" ]]; then
    echo "Error: No attic pod found in namespace '$namespace'." >&2
    exit 1
  fi

  echo -e "Pod:       $YELLOW$BRIGHT$pod$NORMAL"
  echo -e "Subject:   ${BRIGHT}${BLUE}admin${NORMAL}"
  echo -e "Validity:  $BRIGHT$MAGENTA$validity$NORMAL"
  echo -e "Access:    all permissions on *"
  echo ""

  kubectl exec -n "$namespace" "$pod" -c app -- \
    atticadm make-token -f /config/server.toml \
    --sub admin --validity "$validity" \
    --pull "*" --push "*" --delete "*" \
    --create-cache "*" --configure-cache "*" \
    --configure-cache-retention "*" --destroy-cache "*"
}

cmd_create_token_ci() {
  local namespace="$1"
  shift

  local validity=""
  local cache=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --validity)
      validity="$2"
      shift 2
      ;;
    --cache)
      cache="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage
      ;;
    esac
  done

  if [[ -z "$validity" ]]; then
    echo "Error: --validity is required." >&2
    usage
  fi
  if [[ -z "$cache" ]]; then
    echo "Error: --cache is required." >&2
    usage
  fi

  local pod
  pod=$(get_pod "$namespace")
  if [[ -z "$pod" ]]; then
    echo "Error: No attic pod found in namespace '$namespace'." >&2
    exit 1
  fi

  echo -e "Pod:       $YELLOW$BRIGHT$pod$NORMAL"
  echo -e "Subject:   ${BRIGHT}${BLUE}ci${NORMAL}"
  echo -e "Validity:  $BRIGHT$MAGENTA$validity$NORMAL"
  echo -e "Cache:     $BRIGHT$GREEN$cache$NORMAL"
  echo -e "Access:    pull, push"
  echo ""

  kubectl exec -n "$namespace" "$pod" -c app -- \
    atticadm make-token -f /config/server.toml \
    --sub ci --validity "$validity" \
    --pull "$cache" --push "$cache"
}

cmd_create_token_custom() {
  local namespace="$1"
  local subject="$2"
  shift 2

  local validity=""
  local perm_pull=""
  local perm_push=""
  local perm_delete=""
  local perm_create_cache=""
  local perm_configure_cache=""
  local perm_configure_cache_retention=""
  local perm_destroy_cache=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --validity)
      validity="$2"
      shift 2
      ;;
    --pull)
      perm_pull="$2"
      shift 2
      ;;
    --push)
      perm_push="$2"
      shift 2
      ;;
    --delete)
      perm_delete="$2"
      shift 2
      ;;
    --create-cache)
      perm_create_cache="$2"
      shift 2
      ;;
    --configure-cache)
      perm_configure_cache="$2"
      shift 2
      ;;
    --configure-cache-retention)
      perm_configure_cache_retention="$2"
      shift 2
      ;;
    --destroy-cache)
      perm_destroy_cache="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage
      ;;
    esac
  done

  if [[ -z "$validity" ]]; then
    echo "Error: --validity is required." >&2
    usage
  fi

  local pod
  pod=$(get_pod "$namespace")
  if [[ -z "$pod" ]]; then
    echo "Error: No attic pod found in namespace '$namespace'." >&2
    exit 1
  fi

  echo -e "Pod:      $YELLOW$BRIGHT$pod$NORMAL"
  echo -e "Subject:  $BRIGHT$BLUE$subject$NORMAL"
  echo -e "Validity: $BRIGHT$MAGENTA$validity$NORMAL"
  [[ -n "$perm_pull" ]]                     && echo -e "  pull:                      $BRIGHT$GREEN$perm_pull$NORMAL"
  [[ -n "$perm_push" ]]                     && echo -e "  push:                      $BRIGHT$GREEN$perm_push$NORMAL"
  [[ -n "$perm_delete" ]]                   && echo -e "  delete:                    $BRIGHT$GREEN$perm_delete$NORMAL"
  [[ -n "$perm_create_cache" ]]             && echo -e "  create-cache:              $BRIGHT$GREEN$perm_create_cache$NORMAL"
  [[ -n "$perm_configure_cache" ]]          && echo -e "  configure-cache:           $BRIGHT$GREEN$perm_configure_cache$NORMAL"
  [[ -n "$perm_configure_cache_retention" ]] && echo -e "  configure-cache-retention: $BRIGHT$GREEN$perm_configure_cache_retention$NORMAL"
  [[ -n "$perm_destroy_cache" ]]            && echo -e "  destroy-cache:             $BRIGHT$GREEN$perm_destroy_cache$NORMAL"
  echo ""

  local args=(atticadm make-token -f /config/server.toml --sub "$subject" --validity "$validity")
  [[ -n "$perm_pull" ]]                     && args+=(--pull "$perm_pull")
  [[ -n "$perm_push" ]]                     && args+=(--push "$perm_push")
  [[ -n "$perm_delete" ]]                   && args+=(--delete "$perm_delete")
  [[ -n "$perm_create_cache" ]]             && args+=(--create-cache "$perm_create_cache")
  [[ -n "$perm_configure_cache" ]]          && args+=(--configure-cache "$perm_configure_cache")
  [[ -n "$perm_configure_cache_retention" ]] && args+=(--configure-cache-retention "$perm_configure_cache_retention")
  [[ -n "$perm_destroy_cache" ]]            && args+=(--destroy-cache "$perm_destroy_cache")

  kubectl exec -n "$namespace" "$pod" -c app -- "${args[@]}"
}

cmd_exec() {
  local namespace="$1"

  local pod
  pod=$(get_pod "$namespace")
  if [[ -z "$pod" ]]; then
    echo "Error: No attic pod found in namespace '$namespace'." >&2
    exit 1
  fi

  echo -e "Opening shell in pod: $YELLOW$BRIGHT$pod$NORMAL"
  kubectl exec -n "$namespace" -it "$pod" -c app -- /bin/sh
}

# Parse global flags
while getopts "hn:" opt; do
  case $opt in
  h)
    usage
    ;;
  n)
    NAMESPACE="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  esac
done

shift $((OPTIND - 1))

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
create)
  SUBCOMMAND="${1:-}"
  shift || true
  case "$SUBCOMMAND" in
  token)
    TOKEN_TYPE="${1:-}"
    if [[ -z "$TOKEN_TYPE" ]]; then
      echo "Error: token type or subject is required." >&2
      usage
    fi
    shift
    case "$TOKEN_TYPE" in
    admin)
      cmd_create_token_admin "$NAMESPACE" "$@"
      ;;
    ci)
      cmd_create_token_ci "$NAMESPACE" "$@"
      ;;
    *)
      cmd_create_token_custom "$NAMESPACE" "$TOKEN_TYPE" "$@"
      ;;
    esac
    ;;
  *)
    echo "Unknown subcommand: $SUBCOMMAND" >&2
    usage
    ;;
  esac
  ;;
exec)
  cmd_exec "$NAMESPACE"
  ;;
"")
  usage
  ;;
*)
  echo "Unknown command: $COMMAND" >&2
  usage
  ;;
esac
