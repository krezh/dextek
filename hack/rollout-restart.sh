#!/usr/bin/env bash

# Exclude argument
exclude="$1"

# Function to perform rolling restart for Deployments
rolling_restart_deployments() {
  kubectl get deployments --all-namespaces -o json | \
    jq -r ".items[] | select(.metadata.name != \"$exclude\") | \"kubectl rollout restart deployment \(.metadata.name) -n \(.metadata.namespace)\""
}

# Function to perform rolling restart for DaemonSets
rolling_restart_daemonsets() {
  kubectl get daemonsets --all-namespaces -o json | \
    jq -r ".items[] | select(.metadata.name != \"$exclude\") | \"kubectl rollout restart daemonset \(.metadata.name) -n \(.metadata.namespace)\""
}

# Function to perform rolling restart for StatefulSets
rolling_restart_statefulsets() {
  kubectl get statefulsets --all-namespaces -o json | \
    jq -r ".items[] | select(.metadata.name != \"$exclude\") | \"kubectl rollout restart statefulset \(.metadata.name) -n \(.metadata.namespace)\""
}

# Function to run commands in parallel with a specified number of processes
run_parallel() {
  local command_list=$1
  local num_processes=$2

  echo "$command_list" | xargs -I CMD -P "$num_processes" bash -c 'CMD'
}

# Set the number of processes you want to run simultaneously
num_simultaneous_processes=3

# Run rolling restart in parallel for Deployments, DaemonSets, and StatefulSets
run_parallel "$(rolling_restart_deployments)" "$num_simultaneous_processes"
run_parallel "$(rolling_restart_daemonsets)" "$num_simultaneous_processes"
run_parallel "$(rolling_restart_statefulsets)" "$num_simultaneous_processes"
