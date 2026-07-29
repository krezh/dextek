#!/usr/bin/env bash
#
# talos-hard-reset.sh — last-resort hard reset of Talos nodes via sysrq.
#
# Bypasses the Talos sequencer entirely by running a debug container on the
# node, mounting a fresh procfs (the container's own /proc is read-only), and
# triggering sysrq 'b' — an immediate kernel reset.
#
# USE THIS ONLY when the normal paths have failed:
#   talosctl reboot                    (graceful)
#   talosctl reboot --mode force       (skips graceful userland teardown)
#   talosctl reboot --mode powercycle  (skips kexec)
# ...and the node is wedged in a sequence, e.g. "reboot failed: locked".
#
# This is equivalent to pressing the reset button. Nothing is flushed to disk.
# It is a RESET, not a power off — the machine comes back on its own.
#
# NOTE: no sysrq 's' (sync) is issued first. On a node with hung Ceph/NFS
# mounts, sync blocks in uninterruptible sleep and never returns, which would
# defeat the purpose. Filesystems recover on the next boot via journal replay.
#
# Requires: talosctl with a valid talosconfig, Talos v1.12+ (for `debug`),
# and a working registry path on the node to pull the image.
#
set -uo pipefail

IMAGE="${IMAGE:-docker.io/library/alpine:latest}"
TIMEOUT="${TIMEOUT:-90}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-300}"
ASSUME_YES=0
DO_WAIT=0
DRY_RUN=0

# The payload. Runs inside the debug container.
#   - /proc is mounted read-only, so a fresh procfs instance is mounted at
#     /hostproc, which comes up writable.
#   - sysrq 'b' resets immediately.
# IMPORTANT: no commas anywhere in this string. talosctl's --args is a
# comma-separated string slice and will split the command if you add one.
# (This is why it says `mount -t proc` and not `mount -o remount,rw`.)
PAYLOAD='mkdir -p /hostproc && mount -t proc proc /hostproc && echo b > /hostproc/sysrq-trigger'

usage() {
    cat <<'EOF'
Usage: talos-hard-reset.sh [options] <node> [node...]

Hard-resets one or more Talos nodes via sysrq, bypassing the sequencer.

Options:
  -y, --yes         Skip the confirmation prompt.
  -w, --wait        After resetting, wait for each node's API to answer again.
  -n, --dry-run     Print what would be run without touching anything.
  -h, --help        Show this help.

Environment:
  IMAGE             Container image to use    (default: docker.io/library/alpine:latest)
  TIMEOUT           Seconds to wait per node  (default: 90)
  WAIT_TIMEOUT      Seconds to wait for boot  (default: 300, with --wait)
  TALOSCONFIG       Passed through to talosctl.

Examples:
  # Reset one node
  ./talos-hard-reset.sh ms01-01.k8s.plexuz.xyz

  # Reset the whole cluster and wait for it to come back
  ./talos-hard-reset.sh -y -w ms01-0{1,2,3}.k8s.plexuz.xyz

  # See what it would do
  ./talos-hard-reset.sh --dry-run ms01-01.k8s.plexuz.xyz
EOF
}

NODES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)     ASSUME_YES=1; shift ;;
        -w|--wait)    DO_WAIT=1; shift ;;
        -n|--dry-run) DRY_RUN=1; shift ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)            NODES+=("$1"); shift ;;
    esac
done

if [[ ${#NODES[@]} -eq 0 ]]; then
    echo "Error: no nodes specified." >&2
    usage >&2
    exit 2
fi

command -v talosctl >/dev/null 2>&1 || {
    echo "Error: talosctl not found in PATH." >&2
    exit 1
}

echo "Nodes to hard-reset:"
printf '  - %s\n' "${NODES[@]}"
echo
echo "This issues an immediate kernel reset. No unmount, no sync, no drain."
echo "In-flight writes on these nodes will be lost."
echo

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] Per node, would run:"
    echo "  talosctl -n <node> debug $IMAGE --args /bin/sh --args -c --args '$PAYLOAD'"
    exit 0
fi

if [[ $ASSUME_YES -ne 1 ]]; then
    read -r -p "Type RESET to proceed: " confirm
    [[ "$confirm" == "RESET" ]] || { echo "Aborted."; exit 1; }
    echo
fi

reset_node() {
    local node="$1"
    echo "==> $node: triggering reset"

    # talosctl will hang or error when the node dies mid-call. That is the
    # success case, so the exit status here tells us little; `timeout` caps it.
    timeout "$TIMEOUT" talosctl -n "$node" debug "$IMAGE" \
        --args /bin/sh \
        --args -c \
        --args "$PAYLOAD" 2>&1 | sed "s/^/    $node: /"

    echo "    $node: command returned (node should be resetting)"
}

wait_for_node() {
    local node="$1"
    local deadline=$(( SECONDS + WAIT_TIMEOUT ))

    echo "==> $node: waiting for API (timeout ${WAIT_TIMEOUT}s)"
    # Give it a moment to actually go down, so we don't match the pre-reset API.
    sleep 15
    while (( SECONDS < deadline )); do
        if talosctl -n "$node" version --timeout 5s >/dev/null 2>&1; then
            echo "    $node: back up"
            return 0
        fi
        sleep 10
    done
    echo "    $node: did NOT come back within ${WAIT_TIMEOUT}s" >&2
    return 1
}

FAILED=()

for node in "${NODES[@]}"; do
    reset_node "$node"
done

if [[ $DO_WAIT -eq 1 ]]; then
    echo
    for node in "${NODES[@]}"; do
        wait_for_node "$node" || FAILED+=("$node")
    done
fi

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "Nodes that did not return:"
    printf '  - %s\n' "${FAILED[@]}"
    echo
    echo "If a node stays down, it is a power problem now, not a software one."
    exit 1
fi

echo "Done."
if [[ $DO_WAIT -eq 1 ]]; then
    cat <<'EOF'

Post-reset checklist:
  talosctl -n <cp-node> service etcd        # etcd quorum first
  talosctl -n <cp-node> etcd members
  kubectl get nodes                         # once the apiserver answers
  kubectl uncordon <node>                   # cordons do not clear themselves
  kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s
EOF
fi
