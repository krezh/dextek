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
    #!/usr/bin/env bash
    if [ -z "{{ node }}" ]; then
        echo "Error: node argument is required"
        exit 1
        else if [ "{{ node }}" = "all" ]; then
          # Find all controlplane_*.yaml files and apply them
          for file in controlplane_*.yaml; do
            node_name=$(basename "$file" .yaml | cut -d'_' -f2)
            echo "Applying configuration for node: $node_name from file: $file"
            talosctl apply -f $file -n $node_name.k8s.plexuz.xyz -e $node_name.k8s.plexuz.xyz
          done
          exit 0
        fi
    fi
    talosctl apply -f controlplane_{{ node }}.yaml -n {{ node }}.k8s.plexuz.xyz
