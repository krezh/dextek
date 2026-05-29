set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

set quiet
set lazy

VOLSYNC_RESOURCES_DIR := justfile_dir() + "/resources"

_default:
    @just --list volsync

# Suspend Volsync
suspend:
    flux --namespace flux-system suspend kustomization volsync
    flux --namespace volsync suspend helmrelease volsync
    kubectl --namespace volsync scale deployment volsync --replicas 0

# Resume Volsync
resume:
    flux --namespace flux-system resume kustomization volsync
    flux --namespace volsync resume helmrelease volsync
    kubectl --namespace volsync scale deployment volsync --replicas 1

# Snapshot an app
snapshot app ns="default":
    kubectl --namespace {{ ns }} patch replicationsources {{ app }} --type merge -p '{"spec":{"trigger":{"manual":"'$(date +%s)'"}}}'
    until kubectl --namespace {{ ns }} get job/volsync-src-{{ app }} &>/dev/null; do sleep 5; done
    kubectl --namespace {{ ns }} wait job/volsync-src-{{ app }} --for=condition=complete --timeout=120m

# Restore an app from the latest snapshot
restore app ns="default":
    #!/usr/bin/env bash
    set -euo pipefail
    CONTROLLER=$(kubectl --namespace {{ ns }} get deployment {{ app }} &>/dev/null && echo deployment || echo statefulset)
    export NS="{{ ns }}"
    export APP="{{ app }}"
    export ACCESS_MODES=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.accessModes[0]}')
    export STORAGE_CLASS_NAME=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.storageClassName}')
    export SNAPSHOT_CLASS_NAME=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.volumeSnapshotClassName}')
    export CACHE_CAPACITY=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.cacheCapacity}')
    export CACHE_STORAGE_CLASS_NAME=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.cacheStorageClassName}')
    export CAPACITY=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.cacheCapacity}')
    export PUID=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.moverSecurityContext.runAsUser}')
    export PGID=$(kubectl --namespace {{ ns }} get replicationsources/{{ app }} --output=jsonpath='{.spec.kopia.moverSecurityContext.runAsGroup}')
    # Suspend
    flux --namespace flux-system suspend kustomization {{ app }}
    flux --namespace {{ ns }} suspend helmrelease {{ app }}
    kubectl --namespace {{ ns }} scale ${CONTROLLER}/{{ app }} --replicas 0
    kubectl --namespace {{ ns }} wait pod --for=delete --selector="app.kubernetes.io/name={{ app }}" --timeout=5m
    # Restore
    minijinja-cli {{ VOLSYNC_RESOURCES_DIR }}/replicationdestination.yaml.j2 | kubectl apply --server-side --filename -
    until kubectl --namespace {{ ns }} get job/volsync-dst-{{ app }}-dst &>/dev/null; do sleep 5; done
    kubectl --namespace {{ ns }} wait job/volsync-dst-{{ app }}-dst --for=condition=complete --timeout=120m
    kubectl --namespace {{ ns }} delete replicationdestination {{ app }}-dst
    # Resume
    flux --namespace flux-system resume kustomization {{ app }}
    flux --namespace {{ ns }} resume helmrelease {{ app }}
    flux --namespace {{ ns }} reconcile helmrelease {{ app }} --force
    kubectl --namespace {{ ns }} wait pod --for=condition=ready --selector="app.kubernetes.io/name={{ app }}" --timeout=5m
