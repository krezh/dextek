# Bootstrap

_This assumes you are in the **dextek** cluster directory_

## Cilium

### Install Cilium (CNI)

```properties
kubectl kustomize --enable-helm ./bootstrap/cilium | kubectl apply -f - && \
  rm -rf ./bootstrap/cilium/charts
```

## Flux

### Install Flux

```properties
kubectl apply --server-side --kustomize ./bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with **kubectl** in the regular fashion due to being encrypted with sops_

```properties
sops --decrypt bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt bootstrap/flux/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```properties
kubectl apply --server-side --kustomize ./flux/config
```
