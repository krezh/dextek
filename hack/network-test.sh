#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
NODES=("ms01-01" "ms01-02" "ms01-03")

echo "=== Network Performance Test Between Nodes ==="
echo "Namespace: $NAMESPACE"
echo "Nodes: ${NODES[*]}"
echo ""

# Cleanup function
cleanup() {
  echo "Cleaning up..."
  kubectl delete pod -n "$NAMESPACE" -l app=iperf3-test --ignore-not-found=true
}
trap cleanup EXIT

# Create iperf3 server pod on each node
echo "Creating iperf3 server pods..."
for node in "${NODES[@]}"; do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: iperf3-${node}
  namespace: $NAMESPACE
  labels:
    app: iperf3-test
    node: ${node}
spec:
  nodeName: ${node}
  hostNetwork: true
  containers:
  - name: iperf3
    image: networkstatic/iperf3:latest
    command: ["iperf3"]
    args: ["-s"]
    resources:
      requests:
        cpu: 100m
        memory: 128M
      limits:
        cpu: 2000m
        memory: 256M
EOF
done

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
for node in "${NODES[@]}"; do
  kubectl wait --for=condition=Ready "pod/iperf3-${node}" -n "$NAMESPACE" --timeout=60s
done

echo ""
echo "Getting node IPs..."
declare -A NODE_IPS
for node in "${NODES[@]}"; do
  NODE_IPS[$node]=$(kubectl get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  echo "${node}: ${NODE_IPS[$node]}"
done

echo ""
echo "=== Running Tests ==="
echo ""

# Run iperf3 tests between all node pairs
for src_node in "${NODES[@]}"; do
  for dst_node in "${NODES[@]}"; do
    if [ "$src_node" == "$dst_node" ]; then
      continue
    fi

    dst_ip="${NODE_IPS[$dst_node]}"
    echo "Testing: ${src_node} -> ${dst_node} (${dst_ip})"
    kubectl exec -n "$NAMESPACE" "iperf3-${src_node}" -- \
      iperf3 -c "$dst_ip" -t 10 -P 4 | \
      grep -E "sender|receiver" | tail -2
    echo ""
    sleep 2  # Wait before next test
  done
done

echo "=== Test Complete ==="
