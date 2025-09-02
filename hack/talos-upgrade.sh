#!/usr/bin/env bash

# Colors & Text
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)

# Default Variables
NEW_VERSION=""
IMAGE="factory.talos.dev/metal-installer"
SCHEMA_ID=""
NODE=()
FORCE=false

shutdown() {
  tput cnorm # reset cursor
}

trap shutdown EXIT

usage() {
  echo -e "Usage: $0 -n <node1,node2> -v <version> [-f] [-s <schema>] [-A]"
  echo -e "  -n: Comma-separated list of nodes (required unless -A is used)"
  echo -e "  -v: New version to upgrade to (required)"
  echo -e "  -f: Force upgrade even if versions match"
  echo -e "  -s: Schema ID"
  echo -e "  -A: All nodes"
  echo -e "\nExample: $0 -A -v <version>"
  exit 1
}

while getopts "hn:v:s:FA" opt; do
  case $opt in
  h)
    usage
    ;;
  n)
    IFS=',' read -r -a NODE <<<"$OPTARG"
    ;;
  v)
    NEW_VERSION="v${OPTARG}"
    ;;
  s)
    SCHEMA_ID="${OPTARG}"
    ;;
  F)
    FORCE=true
    ;;
  A)
    temp=$(talosctl get nodenames -o json | jq -r .node | paste -sd, -)
    IFS=',' read -r -a NODE <<<"$temp"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "${NEW_VERSION}" ]; then
  echo "Error: -v <version> is required."
  usage
fi
if [ "${#NODE[@]}" -eq 0 ]; then
  echo "Error: No nodes specified. Use -n or -A."
  usage
fi

get_current_version() {
  CURRENT_VERSION="$(talosctl get version -o json -n "$node" | jq -r '.spec["version"]')"
}

check_talos_health() {
  talosctl --nodes "$node" health --wait-timeout=10m --server=false
}

# Check if versions are the same
check_if_same() {
  if [[ "${CURRENT_VERSION}" == "${NEW_VERSION}" ]]; then
    if [[ ${FORCE} == false ]]; then
      printf "Versions are the same. skipping...\n\n"
      return 1
    else
      echo -e "Forcing upgrade..."
      return 0
    fi
  fi
}

check_node_exist() {
  if ! talosctl get nodenames -n "$node" >/dev/null 2>&1; then
    echo -e "Node: \"$node\" does not exist"
    exit 1
  fi
}

get_node_schema_id() {
  if [[ -z "$SCHEMA_ID" ]]; then
    node=$(echo "$node" | cut -d. -f1)
    talosctl -n "$node" get nodestatus -o json | jq -r '.spec.annotations["extensions.talos.dev/schematic"]'
  else
    echo -e "$SCHEMA_ID"
    return
  fi
}

upgrade_talos() {
  echo -e "Upgrading Node: $YELLOW$BRIGHT$node$NORMAL" "$BRIGHT$MAGENTA$CURRENT_VERSION$NORMAL -> $BRIGHT$BLUE$NEW_VERSION$NORMAL"

  check_if_same || return
  SCHEMA_ID=$(get_node_schema_id)
  printf "Schema ID: %s\n" "$SCHEMA_ID"
  printf "Using Image: %s\n" "$IMAGE/$SCHEMA_ID:$NEW_VERSION"
  talosctl upgrade -n "$node" --image "$IMAGE/$SCHEMA_ID:$NEW_VERSION"

  check_talos_health &

  # Wait for jobs
  wait "$(jobs -pr)"
  get_current_version
  printf "Upgraded Node: %s to version: %s\n\n" "$YELLOW$BRIGHT$node$NORMAL" "$BRIGHT$GREEN$CURRENT_VERSION$NORMAL"
}

for node in "${NODE[@]}"; do
  check_node_exist
  get_current_version
  upgrade_talos
done
