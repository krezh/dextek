#!/usr/bin/env just --justfile

set quiet
set ignore-comments

_default:
  just --list

# Sync Recipes
mod sync '.just/sync.just'

# Kube Recipes
mod kube '.just/kube.just'

# Rook Recipes
mod rook '.just/rook.just'

# Talos Recipes
mod talos '.just/talos.just'

# Crunchy Recipes
mod crunchy '.just/crunchy.just'

# SOPS Recipes
mod sops '.just/sops.just'

# Bootstrap Cluster
bootstrap cluster recipe="all":
  echo "Bootstrapping cluster: {{cluster}}..."
  just ./clusters/{{cluster}}/{{recipe}}

[private]
log lvl msg:
  gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}"
