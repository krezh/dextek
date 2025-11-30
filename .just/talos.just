set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

hack_dir := justfile_dir() + '/hack'
controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`

_default:
    @just --list sync

# Reset Talos Nodes
reset:
    #!/usr/bin/env bash
    set -euo pipefail
    ARGS="--reboot --graceful=false --wipe-mode=all --wait=false"
    NODES=$(talosctl config info --output json | jq --raw-output '.endpoints[]' | tr '\n' ' ' | awk '{$1=$1};1')
    for node in $NODES; do
      (
        echo "$node: resetting"
        until talosctl reset -n $node -e $node $ARGS; do sleep 3; done
        echo "$node: done"
      ) &
    done
    wait

# Upgrade talos version on all nodes
upgrade-all version:
    {{ hack_dir }}/talos-upgrade.sh -A -v {{ version }}

# Upgrade Kubernetes version in the cluster
upgrade-k8s version:
    talosctl -n "{{ controller }}" upgrade-k8s --to {{ version }}

etcd-defrag:
    #!/usr/bin/env bash
    set -euo pipefail
    NODES=$(talosctl config info --output json | jq --raw-output '.endpoints[]' | tr '\n' ' ' | awk '{$1=$1};1')
    talosctl etcd status
    for node in $NODES; do
      (
        echo "$node: defragging"
        until talosctl etcd defrag -n $node -e $node; do sleep 1; done
        echo "$node: done"
      ) &
    done
    wait
