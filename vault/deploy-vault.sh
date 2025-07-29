#!/bin/bash

# Script to deploy HashiCorp Vault and integrate it with External Secrets Operator

set -e  # Exit on any error

echo "=== Deploying HashiCorp Vault ==="

# Deploy Vault
echo "1. Deploying Vault..."
kubectl apply -f vault-deployment.yaml

# Wait a moment for the deployment to be processed
sleep 5

# Wait for Vault to be ready
echo "2. Waiting for Vault to be ready..."
kubectl wait --for=condition=available deployment/vault -n vault --timeout=120s

# If wait fails, let's check the pod status
if [ $? -ne 0 ]; then
    echo "Vault deployment failed to become available. Checking pod status..."
    kubectl get pods -n vault
    kubectl describe pod -n vault -l app.kubernetes.io/name=vault
    exit 1
fi

# Apply the vault token secret
echo "3. Creating Vault token secret..."
kubectl apply -f ../apps/eksa-dev/vault-token-secret.yaml

# Apply the updated secrets store configuration
echo "4. Updating ClusterSecretStore configuration..."
kubectl apply -f ../apps/eksa-dev/secrets-store.yaml

# Populate Vault with secrets
echo "5. Populating Vault with secrets..."
./populate-vault.sh

echo "=== Vault deployment completed ==="
echo ""
echo "Next steps:"
echo "1. Run the test script to verify the setup: ./test-staging-environment.sh"
echo "2. Monitor the External Secrets Operator logs: kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets"