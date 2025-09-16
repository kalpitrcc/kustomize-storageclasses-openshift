#!/bin/bash

# OpenShift Storage Classes GitOps Validation Script

set -e

echo "🔍 Validating OpenShift Storage GitOps Configuration"
echo "=================================================="
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Not connected to OpenShift cluster"
    exit 1
fi

echo "✅ Connected to cluster: $(oc cluster-info | head -1 | cut -d' ' -f6)"
echo "✅ User: $(oc whoami)"
echo ""

# Check OCS installation
echo "📦 Checking OpenShift Container Storage installation..."
if oc get csv -n openshift-storage | grep -q ocs-operator; then
    echo "✅ OCS Operator is installed"
else
    echo "❌ OCS Operator not found"
    exit 1
fi

# Check storage classes with GitOps labels
echo ""
echo "🏷️  Checking GitOps-managed storage classes..."
GITOPS_SC_COUNT=$(oc get storageclass -l app.kubernetes.io/managed-by=kustomize --no-headers | wc -l)
echo "✅ Found $GITOPS_SC_COUNT GitOps-managed storage classes"

if [ $GITOPS_SC_COUNT -eq 0 ]; then
    echo "❌ No GitOps-managed storage classes found"
    echo "Run: ./deploy.sh base false"
    exit 1
fi

# List the managed storage classes
echo ""
echo "📋 GitOps-managed storage classes:"
oc get storageclass -l app.kubernetes.io/managed-by=kustomize -o custom-columns="NAME:.metadata.name,PROVISIONER:.provisioner,RECLAIM:.reclaimPolicy,CLUSTER:.metadata.labels.cluster\.name"

# Check Ceph storage pools
echo ""
echo "🗄️  Checking Ceph storage pools..."
POOLS_COUNT=$(oc get cephblockpool,cephfilesystem,cephobjectstore -n openshift-storage -l app.kubernetes.io/managed-by=kustomize --no-headers 2>/dev/null | wc -l)
echo "✅ Found $POOLS_COUNT GitOps-managed Ceph storage pools"

if [ $POOLS_COUNT -gt 0 ]; then
    echo ""
    echo "📋 GitOps-managed Ceph pools:"
    oc get cephblockpool,cephfilesystem,cephobjectstore -n openshift-storage -l app.kubernetes.io/managed-by=kustomize -o custom-columns="NAME:.metadata.name,TYPE:.kind,CLUSTER:.metadata.labels.cluster\.name"
fi

# Test storage functionality
echo ""
echo "🧪 Testing storage functionality..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: validation-test-pvc
  annotations:
    description: "Validation test PVC for GitOps-managed storage"
spec:
  accessModes: 
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF

# Wait for PVC to be bound
echo "⏳ Waiting for PVC to be bound..."
sleep 5

PVC_STATUS=$(oc get pvc validation-test-pvc -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" = "Bound" ]; then
    echo "✅ Storage test successful - PVC is bound"
    oc delete pvc validation-test-pvc
    echo "🧹 Cleaned up test PVC"
else
    echo "❌ Storage test failed - PVC status: $PVC_STATUS"
    oc get pvc validation-test-pvc
    oc delete pvc validation-test-pvc
    exit 1
fi

echo ""
echo "🎉 All validations passed!"
echo ""
echo "📊 Summary:"
echo "- GitOps-managed storage classes: $GITOPS_SC_COUNT"
echo "- GitOps-managed Ceph pools: $POOLS_COUNT"
echo "- Storage functionality: ✅ Working"
echo ""
echo "🔧 Next steps:"
echo "- Deploy to dev: ./deploy.sh dev false"
echo "- Deploy to prod: ./deploy.sh prod false"
echo "- Set up ArgoCD/Flux for automated GitOps"