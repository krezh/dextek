#!/usr/bin/env bash
set -euo pipefail

echo "Starting KubeVirt removal from cluster..."

echo ""
echo "Step 1: Deleting Flux Kustomizations..."
kubectl delete kustomization -n flux-system kubevirt-vms --ignore-not-found=true
kubectl delete kustomization -n flux-system kubevirt-cdi --ignore-not-found=true
kubectl delete kustomization -n flux-system kubevirt --ignore-not-found=true

echo ""
echo "Step 2: Deleting VMs and related resources..."
kubectl delete virtualmachines --all -n kubevirt --wait=false --ignore-not-found=true 2>/dev/null || true
kubectl delete virtualmachineinstances --all -n kubevirt --wait=false --ignore-not-found=true 2>/dev/null || true
kubectl delete datavolumes --all -n kubevirt --wait=false --ignore-not-found=true 2>/dev/null || true

echo ""
echo "Step 3: Deleting ValidatingWebhookConfigurations..."
kubectl delete validatingwebhookconfiguration virt-operator-validator --ignore-not-found=true
kubectl delete validatingwebhookconfiguration cdi-api-datavolume-validate --ignore-not-found=true
kubectl delete validatingwebhookconfiguration cdi-api-populator-validate --ignore-not-found=true
kubectl delete validatingwebhookconfiguration cdi-api-validate --ignore-not-found=true

echo ""
echo "Step 4: Deleting MutatingWebhookConfigurations..."
kubectl delete mutatingwebhookconfiguration virt-api-mutator --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration cdi-api-datavolume-mutate --ignore-not-found=true

echo ""
echo "Step 5: Deleting KubeVirt and CDI operators..."
kubectl delete kubevirt kubevirt -n kubevirt --wait=false --ignore-not-found=true 2>/dev/null || true
kubectl delete cdi cdi -n kubevirt --wait=false --ignore-not-found=true 2>/dev/null || true

echo ""
echo "Step 6: Removing finalizers (if resources are stuck)..."
kubectl patch kubevirt kubevirt -n kubevirt -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
kubectl patch cdi cdi -n kubevirt -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true

echo ""
echo "Step 7: Deleting kubevirt namespace..."
kubectl delete namespace kubevirt --wait=false --ignore-not-found=true

echo ""
echo "Step 8: Deleting APIServices..."
kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true
kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true
kubectl delete apiservice v1beta1.subresources.kubevirt.io --ignore-not-found=true
kubectl delete apiservice v1.upload.cdi.kubevirt.io --ignore-not-found=true

echo ""
echo "Step 9: Deleting CRDs..."
kubectl get crds -o name | grep kubevirt | xargs -r kubectl delete --wait=false 2>/dev/null || true
kubectl get crds -o name | grep "cdi.kubevirt.io" | xargs -r kubectl delete --wait=false 2>/dev/null || true

echo ""
echo "KubeVirt removal initiated. Some resources may take time to fully terminate."
echo "Run 'kubectl get crds | grep kubevirt' to check if CRDs are fully removed."
