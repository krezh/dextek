#!/usr/bin/env bash

# Colors & Text
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)

# Default Variables
NEW_VERSION="v1.9.2" # renovate: datasource=docker depName=ghcr.io/siderolabs/installer
IMAGE="zot.int.plexuz.xyz/factory.talos.dev/installer"
NODE=""
CHECK_SLEEP=3
UPGRADE_INTERVAL=300 # 5m
FORCE=false
SERVICE=false

shutdown() {
  tput cnorm # reset cursor
}

trap shutdown EXIT

usage() {
  echo -e "Idiot!"
  exit 1
}

while getopts ":fn:v:AS" opt; do
  case $opt in
  f)
    FORCE=true
    ;;
  n)
    IFS=',' read -r -a NODE <<<"$OPTARG"
    ;;
  v)
    NEW_VERSION="${OPTARG}"
    ;;
  A)
    unset NODE
    NODE=$(talosctl get nodenames -o json | jq -r .node | paste -sd, -)
    IFS=',' read -r -a NODE <<<"$NODE"
    ;;
  S)
    SERVICE=true
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "${NODE}" ] || [ -z "${NEW_VERSION}" ]; then
  usage
fi

get_current_version() {
  CURRENT_VERSION="$(talosctl version -n "$node" |
    awk '/Server:/,/Enabled:/ {if (/Tag:/) print $2}')"
}

check_ceph_health() {
  local ceph_health
  local count
  # Loop until the cluster reports as healthy
  while [[ "$ceph_health" != "HEALTH_OK" || "$count" -lt 3 ]]; do
    # Get the cluster health using the ceph command
    ceph_health="$(kubectl -n rook-ceph exec deploy/rook-ceph-tools -c rook-ceph-tools -- ceph health)"

    # Print the cluster health
    if [[ "$ceph_health" == "HEALTH_OK" ]]; then
      let count++
      echo -e "Ceph Status:$GREEN Healthy$NORMAL $count/3"
    else
      echo -e "Ceph Status:$RED Unhealthy$NORMAL"
    fi

    # Sleep before checking again
    sleep $CHECK_SLEEP
  done
}

check_etcd_health() {
  local etcd_health
  local count
  # Loop until the etcd reports as healthy
  while [[ "$etcd_health" != "OK" || "$count" -lt 3 ]]; do
    # Get the etcd health
    etcd_health=$(talosctl service etcd -n "$node" | awk '/HEALTH/ {print $2}')

    # Print the etcd health
    if [[ "$etcd_health" == "OK" ]]; then
      let count++
      echo -e "ETCD Status:$GREEN Healthy$NORMAL $count/3"
    else
      echo -e "ETCD Status:$RED $etcd_health$NORMAL"
    fi

    # Sleep before checking again
    sleep $CHECK_SLEEP
  done
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
  talosctl get nodenames -n "$node" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "Node: \"$node\" does not exist"
    exit 1
  fi
}

get_node_schema_id() {
  node=$(echo "$node" | cut -d. -f1)
  kubectl get nodes "$node" -o json | jq -r .metadata.annotations[\"extensions.talos.dev/schematic\"]
}

upgrade_talos() {
  echo -e "Upgrading Node: $YELLOW$BRIGHT$node$NORMAL" "$BRIGHT$MAGENTA$CURRENT_VERSION$NORMAL -> $BRIGHT$BLUE$NEW_VERSION$NORMAL"

  check_if_same || return
  SCHEMA_ID=$(get_node_schema_id)
  printf "Schema ID: %s\n" "$SCHEMA_ID"
  printf "Using Image: %s\n" "$IMAGE/$SCHEMA_ID:$NEW_VERSION"
  talosctl upgrade -n "$node" --image "$IMAGE/$SCHEMA_ID:$NEW_VERSION"

  check_ceph_health &
  check_etcd_health &
  # Wait for jobs
  wait $(jobs -pr)
  get_current_version
  printf "Upgraded Node: %s to version: %s\n\n" "$YELLOW$BRIGHT$node$NORMAL" "$BRIGHT$GREEN$CURRENT_VERSION$NORMAL"
}

if [[ ${SERVICE} == true ]]; then
  while [[ ${SERVICE} == true ]]; do
    for node in "${NODE[@]}"; do
      check_node_exist
    done

    for node in "${NODE[@]}"; do
      get_current_version
      upgrade_talos
    done
    echo "Will run again in $(${UPGRADE_INTERVAL} / 60)m"
    sleep $UPGRADE_INTERVAL
  done
elif [[ ${SERVICE} == false ]]; then
  for node in "${NODE[@]}"; do
    check_node_exist
  done

  for node in "${NODE[@]}"; do
    get_current_version
    check_ceph_health
    upgrade_talos
  done
fi