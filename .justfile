#!/usr/bin/env just --justfile

set quiet
set ignore-comments
set lazy

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

# Bootstrap Cluster
mod dextek 'clusters/dextek/Justfile'

[private]
log lvl msg:
  gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}"
