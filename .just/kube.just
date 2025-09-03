set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

_default:
	@just --list kube

# Spawn a shell on a node
node-shell node:
	@kubectl node-shell -n kube-system -x {{node}}

# Prune pods in Failed, Pending, or Succeeded state
prune-pods:
  for phase in Failed Pending Succeeded; do \
      kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true; \
  done