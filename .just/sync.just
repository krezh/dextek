set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

_default:
    @just --list sync

# Sync External Secrets
es:
    kubectl get es -A --no-headers | while read -r ns name _; do \
      kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite es "${name}" force-sync="$(date +%s)"; \
    done

# Sync GitRepositories
git:
    @kubectl get gitrepo -A --no-headers | while read -r ns name _; do \
    	kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite gitrepo "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done

# Sync HelmReleases
hr:
    @kubectl get hr -A --no-headers | while read -r ns name _; do \
    	kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite hr "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"; \
    done

# Sync Kustomizations
ks:
    @kubectl get ks -A --no-headers | while read -r ns name _; do \
    	kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite ks "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done

# Sync OCIRepositories
oci:
    @kubectl get ocirepo -A --no-headers | while read -r ns name _; do \
    	kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite ocirepo "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done

# Reset and force reconcile all HelmReleases in all namespaces, 4 at a time
hr-reset:
    @kubectl get hr -A --no-headers | awk '{print $1, $2}' | \
      xargs -P 4 -n 2 sh -c 'flux reconcile helmrelease --reset --force -n "$0" "$1"'
