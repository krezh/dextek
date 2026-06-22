set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']
set quiet

PULUMI_FLAGS := "--stack dextek --suppress-permalink=true"

_default:
    just --list

# pulumi preview
preview:
    pulumi preview {{ PULUMI_FLAGS }}

# pulumi up
up:
    pulumi up --yes --skip-preview {{ PULUMI_FLAGS }}

# bootstrap etcd
bootstrap:
    BOOTSTRAP=1 pulumi up --yes --skip-preview {{ PULUMI_FLAGS }}

# write machineConfigs/talosconfig
talosconfig:
    WRITE_TALOSCONFIG=1 pulumi up --yes --skip-preview {{ PULUMI_FLAGS }}

# write machineConfigs/$node.yaml
machine:
    WRITE_MACHINE_CONFIGS=1 pulumi up --yes --skip-preview {{ PULUMI_FLAGS }}

# apply machine config to a node
machine_apply node: machine
    #!/usr/bin/env bash
    if [ -z "{{ node }}" ]; then
        echo "Error: node argument is required"
        exit 1
    elif [ "{{ node }}" = "all" ]; then
        for file in machineConfigs/*.yaml; do
            node_name=$(basename "$file" .yaml)
            echo "Applying configuration for node: $node_name from file: $file"
            talosctl apply -f "$file" -n $node_name.k8s.plexuz.xyz -e $node_name.k8s.plexuz.xyz
        done
        exit 0
    fi
    talosctl apply -f machineConfigs/{{ node }}.yaml -n {{ node }}.k8s.plexuz.xyz
