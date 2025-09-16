#!/bin/bash

# OpenShift Storage Classes GitOps Deployment Script

set -e

ENVIRONMENT=${1:-base}
DRY_RUN=${2:-false}

echo "🚀 Deploying OpenShift Storage GitOps Configuration"
echo "Environment: $ENVIRONMENT"
echo "Dry Run: $DRY_RUN"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Not connected to OpenShift cluster"
    echo "Please login with: oc login <cluster-url>"
    exit 1
fi

echo "✅ Connected to cluster: $(oc cluster-info | head -1 | cut -d' ' -f6)"
echo "✅ User: $(oc whoami)"
echo ""

# Determine the path to build
if [ "$ENVIRONMENT" = "base" ]; then
    BUILD_PATH="."
elif [ "$ENVIRONMENT" = "dev" ]; then
    BUILD_PATH="environments/dev"
elif [ "$ENVIRONMENT" = "prod" ]; then
    BUILD_PATH="environments/prod"
else
    echo "❌ Error: Unknown environment '$ENVIRONMENT'"
    echo "Valid environments: base, dev, prod"
    exit 1
fi

echo "📋 Building configuration from: $BUILD_PATH"

# Preview the configuration
echo ""
echo "📄 Configuration preview:"
echo "========================"
kustomize build $BUILD_PATH | head -20
echo "... (truncated)"
echo ""

# Apply or dry-run
if [ "$DRY_RUN" = "true" ]; then
    echo "🔍 Performing dry-run..."
    kustomize build $BUILD_PATH | oc apply --dry-run=client -f -
    echo ""
    echo "✅ Dry-run completed successfully!"
    echo "To apply for real, run: ./deploy.sh $ENVIRONMENT false"
else
    echo "⚠️  Applying configuration to cluster..."
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kustomize build $BUILD_PATH | oc apply -f -
        echo ""
        echo "✅ Configuration applied successfully!"
        
        # Verify deployment
        echo ""
        echo "🔍 Verifying deployment..."
        echo "Storage classes with GitOps labels:"
        oc get storageclass -l app.kubernetes.io/managed-by=kustomize
        
        echo ""
        echo "Ceph storage pools:"
        oc get cephblockpool,cephfilesystem,cephobjectstore -n openshift-storage -l app.kubernetes.io/managed-by=kustomize
    else
        echo "❌ Deployment cancelled"
        exit 1
    fi
fi

echo ""
echo "🎉 Done!"