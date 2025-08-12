#!/bin/bash

# Unified Vault deployment and configuration script
# This script combines deployment, token setup, and secret population functionality
# It uses kubectl exec to interact with Vault without requiring Vault CLI locally

set -e  # Exit on any error

echo "=== Deploying and Configuring HashiCorp Vault ==="

# Deploy Vault using the unified manifest
echo "1. Deploying Vault..."
kubectl apply -f apps/infrastructure/vault/unified-vault-setup.yaml

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

# Check if required environment variables are set
echo "3. Validating environment variables..."
if [ -z "$VAULT_TOKEN" ]; then
    echo "Error: VAULT_TOKEN environment variable is not set"
    echo "Please set VAULT_TOKEN before running this script"
    exit 1
fi

if [ -z "$INDEXER_PASSWORD" ]; then
    echo "Error: INDEXER_PASSWORD environment variable is not set"
    echo "Please set INDEXER_PASSWORD before running this script"
    exit 1
fi

if [ -z "$DASHBOARD_PASSWORD" ]; then
    echo "Error: DASHBOARD_PASSWORD environment variable is not set"
    echo "Please set DASHBOARD_PASSWORD before running this script"
    exit 1
fi

if [ -z "$API_PASSWORD" ]; then
    echo "Error: API_PASSWORD environment variable is not set"
    echo "Please set API_PASSWORD before running this script"
    exit 1
fi

# Get Vault pod name
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
echo "Using Vault pod: $VAULT_POD"

# Enable KV secrets engine
echo "4. Enabling KV secrets engine..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault secrets enable -path=secret kv-v2 || echo "KV engine may already be enabled"

# Store indexer secrets
echo "5. Storing indexer secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv put secret/dev/github/wazuh/indexer \
  indexer-username="admin" \
  indexer-password="$INDEXER_PASSWORD" \
  dashboard-username="admin" \
  dashboard-password="$DASHBOARD_PASSWORD"

# Store API secrets
echo "6. Storing API secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv put secret/dev/github/wazuh \
  api-username="wazuh" \
  api-password="$API_PASSWORD"

# Store root CA secrets with enhanced certificate handling
echo "7. Storing root CA secrets..."
# Check if certificate files exist in the traditional location
if [ -f "../../../wazuh-certs/root-ca.pem" ] && [ -f "../../../wazuh-certs/root-ca-key.pem" ]; then
  echo "Using certificate files from ../wazuh-certs/"
  # First, copy the certificate files to the pod
  kubectl cp ../../../wazuh-certs/root-ca.pem vault/$VAULT_POD:/tmp/root-ca.pem
  kubectl cp ../../../wazuh-certs/root-ca-key.pem vault/$VAULT_POD:/tmp/root-ca-key.pem

  # Then store them in Vault
  kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv put secret/dev/github/wazuh/root-ca \
    "ca.crt=@/tmp/root-ca.pem" \
    "ca.key=@/tmp/root-ca-key.pem"
else
  echo "Certificate files not found in ../wazuh-certs/. Checking cert-manager secret..."
  # Check if cert-manager CA secret exists
  if kubectl get secret ca-key-pair -n cert-manager >/dev/null 2>&1; then
    echo "Using CA certificate from cert-manager secret..."
    
    # Extract the certificate and key from the cert-manager secret
    kubectl get secret ca-key-pair -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/ca.crt
    kubectl get secret ca-key-pair -n cert-manager -o jsonpath='{.data.tls\.key}' | base64 -d > /tmp/ca.key
    
    # Copy the extracted files to the Vault pod
    kubectl cp /tmp/ca.crt vault/$VAULT_POD:/tmp/root-ca.pem
    kubectl cp /tmp/ca.key vault/$VAULT_POD:/tmp/root-ca-key.pem
    
    # Store them in Vault
    kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv put secret/dev/github/wazuh/root-ca \
      "ca.crt=@/tmp/root-ca.pem" \
      "ca.key=@/tmp/root-ca-key.pem"
    
    # Clean up temporary files
    rm -f /tmp/ca.crt /tmp/ca.key
  else
    echo "Warning: Neither certificate files in ../wazuh-certs/ nor cert-manager secret found."
    echo "Root CA secrets were not stored. To add them later, ensure either:"
    echo "  1. Certificate files exist in ../wazuh-certs/ directory, or"
    echo "  2. cert-manager is deployed with ca-key-pair secret"
  fi
fi

echo "Vault configured and populated with secrets successfully!"

# Verify the secrets were created
echo "8. Verifying secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv list secret/dev/github/wazuh/
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh/indexer

# Only verify root CA secrets if they were created
if [ -f "../../../wazuh-certs/root-ca.pem" ] && [ -f "../../../wazuh-certs/root-ca-key.pem" ]; then
  kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh/root-ca
elif kubectl get secret ca-key-pair -n cert-manager >/dev/null 2>&1; then
  kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh/root-ca
else
  echo "Skipping root CA verification (certificates were not found)"
fi

echo "All secrets have been successfully stored and verified in Vault!"
