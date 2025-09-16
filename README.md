# OpenShift Storage Classes GitOps Management

Complete GitOps solution for managing OpenShift Container Storage (OCS) StorageClasses and Ceph storage pools using Kustomize.

## 🎯 What This Does

- **GitOps Management**: Manages StorageClasses and Ceph storage pools with proper labels/annotations
- **Environment-Specific**: Different configurations for dev/prod (reclaim policies, etc.)
- **Safe Operations**: Only manages metadata, doesn't modify storage functionality
- **Automation Ready**: Works with ArgoCD, Flux, and other GitOps tools

## 📁 Repository Structure

```
├── kustomization.yaml                    # Main configuration
├── base/
│   ├── kustomization.yaml               # Base resources
│   ├── storage-pools.yaml               # Ceph pools (CephBlockPool, CephFilesystem, CephObjectStore)
│   └── storage-classes-metadata-only.yaml # StorageClass metadata only
├── environments/
│   ├── dev/kustomization.yaml           # Dev environment (Delete reclaim policy)
│   └── prod/kustomization.yaml          # Prod environment (Retain reclaim policy)
├── deploy.sh                            # Deployment automation script
├── validate.sh                          # Validation script
└── argocd-application.yaml              # ArgoCD application example
```

## 📋 Prerequisites

1. **OpenShift cluster** with OCS (OpenShift Container Storage) installed
2. **oc CLI** logged into your cluster with cluster-admin permissions
3. **kustomize** installed (`brew install kustomize` on macOS)

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/your-org/openshift-storage-gitops.git
cd openshift-storage-gitops

# Replace placeholder with your cluster name
sed -i 's/REPLACE_WITH_YOUR_CLUSTER_NAME/my-cluster-name/g' kustomization.yaml
```

### 2. Deploy Using Scripts (Recommended)
```bash
# Test with dry-run first
./deploy.sh base true

# Apply the configuration
./deploy.sh base false

# Validate deployment
./validate.sh
```

### 3. Manual Deployment
```bash
# Preview changes
kustomize build . | oc apply --dry-run=client -f -

# Apply configuration
kustomize build . | oc apply -f -

# Verify GitOps labels were applied
oc get storageclass -l app.kubernetes.io/managed-by=kustomize
```

## 🔧 Environment-Specific Deployments

### Development Environment
```bash
# Deploy to dev (uses Delete reclaim policy)
./deploy.sh dev false
```

### Production Environment
```bash
# Deploy to prod (uses Retain reclaim policy for data safety)
./deploy.sh prod false
```

## 📊 Managed Storage Classes

| Storage Class | Type | Description | Use Case |
|---------------|------|-------------|----------|
| `ocs-storagecluster-ceph-rbd` | Block | Default Ceph RBD storage | General workloads, databases |
| `ocs-storagecluster-ceph-rbd-virtualization` | Block | Optimized for VMs | Virtual machines, CNV |
| `ocs-storagecluster-cephfs` | Filesystem | Shared filesystem | ReadWriteMany workloads |
| `ocs-storagecluster-ceph-rgw` | Object | S3-compatible object storage | Object storage, backups |
| `openshift-storage.noobaa.io` | Object | Multi-cloud gateway | Hybrid cloud storage |

## 🤖 Automation Scripts

### Deployment Script (`deploy.sh`)
```bash
# Usage: ./deploy.sh <environment> <dry-run>
./deploy.sh base true     # Dry-run base config
./deploy.sh base false    # Apply base config
./deploy.sh dev false     # Apply dev environment
./deploy.sh prod false    # Apply prod environment
```

### Validation Script (`validate.sh`)
```bash
# Validates deployment and tests storage functionality
./validate.sh
```

The validation script checks:
- OCS installation
- GitOps-managed storage classes
- Ceph storage pools
- Storage functionality with test PVC

## 🔄 GitOps Integration

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: openshift-storage-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/openshift-storage-gitops
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: false  # Don't delete storage classes
      selfHeal: true
  ignoreDifferences:
    - group: storage.k8s.io
      kind: StorageClass
      jsonPointers:
        - /parameters
        - /provisioner
        - /reclaimPolicy
```

### Flux Kustomization
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: storage-classes
  namespace: flux-system
spec:
  interval: 10m
  path: ./
  prune: false
  sourceRef:
    kind: GitRepository
    name: openshift-storage-gitops
```

## ✅ Verification Commands

```bash
# Check GitOps-managed storage classes
oc get storageclass -l app.kubernetes.io/managed-by=kustomize

# Check Ceph storage pools
oc get cephblockpool,cephfilesystem,cephobjectstore -n openshift-storage -l app.kubernetes.io/managed-by=kustomize

# Test storage functionality
oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF

# Check PVC status and cleanup
oc get pvc test-pvc
oc delete pvc test-pvc
```

## 🛠 Troubleshooting

### Common Issues

**1. "StorageClass not found"**
```bash
# Check OCS installation
oc get csv -n openshift-storage | grep ocs
oc get storageclass
```

**2. "Forbidden: updates to parameters are forbidden"**
This is expected! The configuration only manages metadata, not storage parameters.

**3. Permission denied**
```bash
# Verify cluster admin permissions
oc auth can-i update storageclasses
```

### Debug Commands
```bash
# Check OCS health
oc get pods -n openshift-storage

# View Ceph cluster status
oc get cephcluster -n openshift-storage

# Check storage class details
oc describe storageclass ocs-storagecluster-ceph-rbd
```

## 🔒 Security & Safety

- **Requires cluster-admin permissions**
- **Only modifies metadata** (labels/annotations)
- **Safe for production** - doesn't affect storage functionality
- **No impact on existing PVCs** or storage behavior
- **Environment-specific reclaim policies** prevent accidental data loss

## 🚀 Getting Started Checklist

- [ ] Clone the repository
- [ ] Update cluster name in `kustomization.yaml`
- [ ] Ensure OCS is installed and working
- [ ] Test with dry-run: `./deploy.sh base true`
- [ ] Apply configuration: `./deploy.sh base false`
- [ ] Validate deployment: `./validate.sh`
- [ ] Set up GitOps automation (ArgoCD/Flux)

## 📝 Contributing

1. Fork the repository
2. Test changes with `./deploy.sh base true`
3. Validate with `./validate.sh`
4. Submit a pull request

---

**Ready to push to GitHub!** This configuration provides a complete, production-ready GitOps solution for OpenShift storage management.