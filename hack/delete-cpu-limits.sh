#!/usr/bin/env bash

# Get a list of all namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Iterate over each namespace
for namespace in $namespaces; do
  # Get a list of all pods in the namespace that have a CPU limit set
  pods=$(kubectl get pods -n $namespace -o jsonpath='{.items[?(@.spec.containers[*].resources.limits.cpu)].metadata.name}')

  # Iterate over each pod and delete it
  for pod in $pods; do
    kubectl delete pod $pod -n $namespace &
  done
done

wait
