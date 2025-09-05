set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

set quiet := true

# tofu init
_default:
  just --list

init:
  tofu init --upgrade

# tofu apply
apply: init
  tofu apply --auto-approve

# tofu plan
plan: init
  tofu plan

# tofu apply --var bootstrap=true
bootstrap: init
  tofu apply --var bootstrap=true --auto-approve

# create talosconfig
talosconfig: init
  tofu apply --var talosconfig=true --auto-approve

# create $type_$node.yaml
machine: init
  tofu apply --var machine_yaml=true --auto-approve

# apply machine configs
machine_apply node: machine
  talosctl apply -f controlplane_{{node}}.yaml -n {{node}}.k8s.plexuz.xyz
