# OpenShift Storage Classes and Storage Pools GitOps Management

Complete GitOps configuration for managing OpenShift Container Storage (OCS) StorageClasses and underlying storage pools using Kustomize.

> **Complete Solution**: This configuration manages both StorageClasses AND their underlying storage pools (CephBlockPool, CephFilesystem, CephObjectStore) for full GitOps control.

## 📁 Repository Structure

```
kust-configs/
├── kustomization.yaml           # Main Kustomize configuration
├── base/
│   ├── kustomization.yaml       # Base configuration
│   ├── storage-pools.yaml       # Ceph storage pools definitions
│   └── storage-classes.yaml     # StorageClass definitions
├── environments/
│   ├── dev/
│   │   └── kustomization.yaml   # Development environment config
│   └── prod/
│       └── kustomization.yaml   # Production environment config
├── README.md                   # This documentation
└── .gitignore                 # Git ignore rules
```

## 🎯 What This Does

- **Complete GitOps Management**: Manages both StorageClasses and storage pools
- **Environment-Specific Configurations**: Different settings for dev/prod
- **Storage Pool Management**: Defines CephBlockPool, CephFilesystem, CephObjectStore
- **StorageClass Management**: Complete StorageClass definitions with parameters
- **Safe Deployment**: Environment-specific reclaim policies and configurations

## 📋 Prerequisites

1. **OpenShift cluster** with OCS (OpenShift Container Storage) installed
2. **oc CLI** logged into your cluster
3. **kustomize** installed (`brew install kustomize` on macOS)
4. **Cluster admin permissions** to modify StorageClasses

## 🚀 Quick Start

### Step 1: Clone and Customize
```bash
git clone <your-repo-url>
cd kustomize-storageclasses-openshift


# Replace placeholder with your actual cluster name
sed -i 's/REPLACE_WITH_YOUR_CLUSTER_NAME/my-cluster-name/g' kustomization.yaml
```

### Step 2: Preview Changes (Recommended)
```bash
# See what will be applied
kustomize build . | oc apply --dry-run=client -f -
```

### Step 3: Apply Configuration
```bash
# Apply the GitOps metadata
kustomize build . | oc apply -f -
```

### Step 4: Verify
```bash
# Check that labels and annotations were added
oc get storageclass ocs-storagecluster-ceph-rbd -o yaml
```

## 🔧 Customization for Different Clusters

### Option 1: Direct Edit
Edit `kustomization.yaml` and change the cluster name:
```yaml
labels:
  - pairs:
      cluster.name: your-cluster-name  # Change this
```

### Option 2: Environment-Specific Overlays
Create cluster-specific directories:
```bash
mkdir -p clusters/dev clusters/prod

# Dev cluster
cat > clusters/dev/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../
labels:
  - pairs:
      cluster.name: dev-cluster
      environment: development
EOF

# Apply dev configuration
kustomize build clusters/dev/ | oc apply -f -
```

## 📊 Storage Classes Managed

| Storage Class | Type | Description | Use Case |
|---------------|------|-------------|----------|
| `ocs-storagecluster-ceph-rbd` | Block | Default Ceph RBD storage | General workloads, databases |
| `ocs-storagecluster-ceph-rbd-virtualization` | Block | Optimized for VMs | Virtual machines, CNV |
| `ocs-storagecluster-cephfs` | Filesystem | Shared filesystem | ReadWriteMany workloads |
| `ocs-storagecluster-ceph-rgw` | Object | S3-compatible object storage | Object storage, backups |
| `openshift-storage.noobaa.io` | Object | Multi-cloud gateway | Hybrid cloud storage |

## 🔄 GitOps Integration

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: storage-classes
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/ocp-storage-gitops
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: false  # Don't delete storage classes
      selfHeal: true
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
  prune: false  # Don't delete storage classes
  sourceRef:
    kind: GitRepository
    name: ocp-storage-config
```

## ✅ Validation Commands

```bash
# Check current storage classes
oc get storageclass

# Verify GitOps labels were applied
oc get storageclass -l app.kubernetes.io/managed-by=kustomize

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

# Check PVC status
oc get pvc test-pvc

# Cleanup test
oc delete pvc test-pvc
```

## 🛠 Troubleshooting

### Common Issues

**1. "StorageClass not found" error**
```bash
# Check if OCS is installed
oc get csv -n openshift-storage | grep ocs

# Check storage classes exist
oc get storageclass
```

**2. "Forbidden: updates to parameters are forbidden"**
- This is expected! The configuration only manages metadata, not parameters
- If you see this error, it means you're trying to modify storage class parameters

**3. Permission denied**
```bash
# Ensure you have cluster admin permissions
oc auth can-i update storageclasses
```

### Useful Debug Commands
```bash
# Check OCS health
oc get pods -n openshift-storage

# View Ceph cluster status
oc get cephcluster -n openshift-storage

# Check storage class details
oc describe storageclass ocs-storagecluster-ceph-rbd
```

## 🔒 Security Notes

- This configuration requires cluster-admin permissions
- Only modifies metadata, not storage functionality
- Safe to apply on production clusters
- Does not affect existing PVCs or storage behavior

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with `kustomize build . | oc apply --dry-run=client -f -`
4. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and operational use.