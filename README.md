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

## 🔄 GitOps Integration with ArgoCD

### Prerequisites for ArgoCD
1. **OpenShift GitOps Operator** installed (creates `openshift-gitops` namespace)
2. **Repository pushed to GitHub** with your configurations
3. **Cluster admin access** to create ArgoCD applications

### Step-by-Step ArgoCD Setup

#### 1. Install OpenShift GitOps (if not already installed)
```bash
# Check if GitOps is installed
oc get namespaces | grep gitops

# If not installed, install via OperatorHub or CLI:
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

#### 2. Apply the ArgoCD Application
```bash
# Apply the provided ArgoCD application
oc apply -f argocd-application.yaml

# Verify application is created
oc get applications.argoproj.io -n openshift-gitops
```

#### 3. Access ArgoCD UI
```bash
# Get ArgoCD route
oc get route openshift-gitops-server -n openshift-gitops

# Get admin password
oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d
```

#### 4. Login and Sync
1. **Open ArgoCD UI** using the route URL
2. **Login** with username `admin` and the password from step 3
3. **Find your application**: `openshift-storage-gitops`
4. **Click on the application** to see the resource tree
5. **Click "Sync"** to deploy your storage configuration

### What You'll Achieve with ArgoCD

#### 🎯 **Visual Management**
- **Resource Tree View**: See all 8 managed resources (5 StorageClasses + 3 Ceph pools)
- **Real-time Status**: Monitor sync and health status of each component
- **Drift Detection**: Automatically detect when cluster state differs from Git
- **One-Click Sync**: Deploy changes with a single button click

#### 🔄 **Automated GitOps Workflow**
```
Git Repository → ArgoCD → OpenShift Cluster
     ↓              ↓            ↓
   Commit        Detects      Applies
   Changes       Changes      Changes
```

#### 📊 **ArgoCD UI Features You'll See**

**Application Overview:**
```
📦 openshift-storage-gitops
├── ✅ StorageClass/ocs-storagecluster-ceph-rbd (Synced/Healthy)
├── ✅ StorageClass/ocs-storagecluster-ceph-rbd-virtualization (Synced/Healthy)
├── ✅ StorageClass/ocs-storagecluster-cephfs (Synced/Healthy)
├── ✅ StorageClass/ocs-storagecluster-ceph-rgw (Synced/Healthy)
├── ✅ StorageClass/openshift-storage.noobaa.io (Synced/Healthy)
├── 🗄️ CephBlockPool/ocs-storagecluster-cephblockpool (Synced/Healthy)
├── 🗄️ CephFilesystem/ocs-storagecluster-cephfilesystem (Synced/Healthy)
└── 🗄️ CephObjectStore/ocs-storagecluster-cephobjectstore (Synced/Healthy)
```

#### 🚀 **Automated Capabilities**
- **Self-Healing**: Automatically fixes configuration drift
- **Change Detection**: Monitors Git repository for updates
- **Safe Deployment**: Won't delete storage classes (prune: false)
- **Environment Management**: Switch between dev/prod configurations
- **Rollback Support**: Easy rollback to previous Git commits

#### 🔍 **Monitoring & Observability**
- **Sync History**: Track all deployment changes over time
- **Event Logs**: Detailed logs of sync operations and errors
- **Health Checks**: Real-time health monitoring of storage components
- **Diff View**: Compare Git state vs cluster state
- **Resource Details**: Click any resource to see full YAML configuration

### Testing ArgoCD Integration

#### Quick Test Workflow:
```bash
# 1. Make a change to your configuration
echo "  test-annotation: updated-$(date +%s)" >> kustomization.yaml

# 2. Commit and push to GitHub
git add .
git commit -m "test: update annotation"
git push

# 3. Watch ArgoCD detect and sync the change
# - Open ArgoCD UI
# - See application status change to "OutOfSync"
# - Click "Sync" or wait for auto-sync
# - Watch resources update in real-time
```

#### Environment Testing:
```bash
# Test different environments through ArgoCD
# Update the application to point to different paths:

# For dev environment:
# source.path: environments/dev

# For prod environment:  
# source.path: environments/prod
```

### ArgoCD Application Configuration Explained

The provided `argocd-application.yaml` includes:

- **`prune: false`**: Prevents accidental deletion of storage classes
- **`selfHeal: true`**: Automatically fixes configuration drift
- **`ServerSideApply: true`**: Better handling of resource updates
- **`ignoreDifferences`**: Ignores OpenShift-managed storage parameters
- **Smart sync options**: Optimized for storage resource management

### Troubleshooting ArgoCD

**Application shows "OutOfSync":**
- Check if your GitHub repository is accessible
- Verify the repository URL in the application
- Ensure the path is correct (usually ".")

**Sync fails:**
- Check ArgoCD application logs in the UI
- Verify cluster permissions
- Ensure OCS is properly installed

**Resources show "Unknown" health:**
- This is normal for StorageClasses (they don't have health status)
- Ceph resources should show "Healthy" when OCS is working

### Alternative: Flux Integration
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

## 🧪 Testing ArgoCD Integration

### Complete ArgoCD Test Workflow

#### Prerequisites Check:
```bash
# 1. Verify OpenShift GitOps is installed
oc get pods -n openshift-gitops

# 2. Ensure your repository is pushed to GitHub
git remote -v

# 3. Verify OCS is working
oc get storageclass | grep ocs
```

#### Step-by-Step Testing:

**1. Deploy ArgoCD Application:**
```bash
# Apply the ArgoCD application
oc apply -f argocd-application.yaml

# Check application status
oc get applications.argoproj.io -n openshift-gitops
```

**2. Access ArgoCD UI:**
```bash
# Get the ArgoCD URL
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"

# Get admin password
echo "Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"
```

**3. Test GitOps Workflow:**
```bash
# Make a test change
echo "  test-label: argocd-test-$(date +%s)" >> kustomization.yaml

# Commit and push
git add .
git commit -m "test: ArgoCD integration test"
git push

# Watch in ArgoCD UI:
# - Application will show "OutOfSync"
# - Click "Sync" to apply changes
# - Watch resources update in real-time
```

**4. Verify Results:**
```bash
# Check that GitOps labels are applied
oc get storageclass -l app.kubernetes.io/managed-by=kustomize

# Check Ceph pools
oc get cephblockpool,cephfilesystem,cephobjectstore -n openshift-storage -l app.kubernetes.io/managed-by=kustomize
```

### Expected ArgoCD UI Experience

**🎯 What You'll See:**
1. **Application Dashboard**: `openshift-storage-gitops` with sync status
2. **Resource Tree**: Visual representation of all 8 managed resources
3. **Sync Controls**: Manual sync, refresh, and rollback options
4. **Health Monitoring**: Real-time status of each storage component
5. **Event History**: Complete audit trail of all changes

**🔄 GitOps Benefits You'll Experience:**
- **Declarative Management**: All storage config in Git
- **Automated Deployment**: Changes deploy automatically or on-demand
- **Drift Detection**: Immediate notification of configuration changes
- **Easy Rollbacks**: One-click rollback to any previous state
- **Multi-Environment**: Easy switching between dev/prod configurations

## 🚀 Getting Started Checklist

### Manual Deployment:
- [ ] Clone the repository
- [ ] Update cluster name in `kustomization.yaml`
- [ ] Ensure OCS is installed and working
- [ ] Test with dry-run: `./deploy.sh base true`
- [ ] Apply configuration: `./deploy.sh base false`
- [ ] Validate deployment: `./validate.sh`

### GitOps Deployment (Recommended):
- [ ] Complete manual deployment steps above
- [ ] Push repository to GitHub
- [ ] Install OpenShift GitOps operator
- [ ] Apply ArgoCD application: `oc apply -f argocd-application.yaml`
- [ ] Access ArgoCD UI and sync the application
- [ ] Test GitOps workflow with a test commit


---

