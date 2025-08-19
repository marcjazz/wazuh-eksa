#!/bin/bash


set -e  # Exit on any error


echo "=== Configuring HashiCorp Vault ==="

# Check if required environment variables are set
echo "3. Validating environment variables..."
# Use root token by default if VAULT_TOKEN is not set
# IMPORTANT: Vault is configured with root token "root-token" in development mode
# Do not use random tokens as they won't have the necessary permissions
VAULT_TOKEN=${VAULT_TOKEN:-"root-token"}
echo "Using Vault token: ${VAULT_TOKEN}"

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
echo "Getting Vault pod name..."
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$VAULT_POD" ]; then
    echo "ERROR: Cannot get Vault pod name. Please ensure:"
    echo "  1. Kubernetes cluster is running and accessible"
    echo "  2. Vault is deployed in the 'vault' namespace"
    echo "  3. kubectl is properly configured"
    exit 1
fi
echo "Using Vault pod: $VAULT_POD"

# Setup port forwarding if requested
echo "Setting up port forwarding to Vault pod..."
echo "Forwarding port 8200 to localhost. Access Vault UI at http://localhost:8200"
echo "NOTE: This will run in the background. To stop port forwarding, run:"
echo "  kill \$(pgrep -f \"kubectl port-forward.*\$VAULT_POD.*8200\")"
kubectl port-forward -n vault $VAULT_POD 8200:8200 &
sleep 2  # Give port-forward time to establish
echo "Port forwarding established!"

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
if [ -f "./wazuh-certs/root-ca.pem" ] && [ -f "./wazuh-certs/root-ca-key.pem" ]; then
    echo "Using certificate files from ../wazuh-certs/"
    # First, copy the certificate files to the pod
    kubectl cp ./wazuh-certs/root-ca.pem vault/$VAULT_POD:/tmp/root-ca.pem
    kubectl cp ./wazuh-certs/root-ca-key.pem vault/$VAULT_POD:/tmp/root-ca-key.pem
    
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
if [ -f "./wazuh-certs/root-ca.pem" ] && [ -f "./wazuh-certs/root-ca-key.pem" ]; then
    kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh/root-ca
    elif kubectl get secret ca-key-pair -n cert-manager >/dev/null 2>&1; then
    kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN="$VAULT_TOKEN" vault kv get secret/dev/github/wazuh/root-ca
else
    echo "Skipping root CA verification (certificates were not found)"
fi

echo "All secrets have been successfully stored and verified in Vault!"
