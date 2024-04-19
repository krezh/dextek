#!/usr/bin/env bash

# Colors & Text
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Default Variables
NEW_VERSION="v1.6.7" # renovate: datasource=github-releases depName=siderolabs/talos
IMAGE="zot.int.plexuz.xyz/factory.talos.dev/installer/a1e5fc738deb459b9f9481505e6b67e12334ccac17f0361aa60a1621f26b1c8c"
NODE=""
CHECK_SLEEP=3
UPGRADE_INTERVAL=300 # 5m
FORCE=false
ALL=false
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
    IFS=',' read -r -a NODE <<<$NODE
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

# Shift the options to leave the remaining arguments
shift $((OPTIND - 1))

if [ -z "${NODE}" ] || [ -z "${NEW_VERSION}" ]; then
  usage
fi

get_current_version() {
  CURRENT_VERSION="$(talosctl version -n $node |
    awk '/Server:/,/Enabled:/ {if (/Tag:/) print $2}')"
}

check_ceph_health() {
  local ceph_health
  local count
  # Loop until the cluster reports as healthy
  while [[ "$ceph_health" != "HEALTH_OK" || "$count" < 3 ]]; do
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
  while [[ "$etcd_health" != "OK" || "$count" < 3 ]]; do
    # Get the etcd health
    etcd_health=$(talosctl service etcd -n $node | awk '/HEALTH/ {print $2}')

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
  talosctl get nodenames -n $node >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "Node: \"$node\" does not exist"
    exit 1
  fi
}

upgrade_talos() {
  echo -e "Upgrading Node: $YELLOW$BRIGHT$node$NORMAL" "$BRIGHT$MAGENTA$CURRENT_VERSION$NORMAL -> $BRIGHT$BLUE$NEW_VERSION$NORMAL"

  check_if_same || return
  talosctl upgrade -n $node --image $IMAGE:$NEW_VERSION

  check_ceph_health &
  check_etcd_health &
  # Wait for jobs
  wait $(jobs -pr)
  get_current_version
  printf "Upgraded Node: $YELLOW$BRIGHT$node$NORMAL to version: $BRIGHT$GREEN$CURRENT_VERSION$NORMAL\n\n"
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
    echo "Will run again in $((${UPGRADE_INTERVAL} / 60))m"
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