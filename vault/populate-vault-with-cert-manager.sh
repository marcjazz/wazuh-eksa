#!/bin/bash

# Script to populate Vault secrets using kubectl exec
# This version extracts CA certificates from cert-manager if available

set -e

VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
echo "Using Vault pod: $VAULT_POD"

echo "Enabling KV secrets engine..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault secrets enable -path=secret kv-v2 || echo "KV engine may already be enabled"

echo "Storing indexer secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv put secret/dev/github/wazuh/indexer \
  indexer-username="admin" \
  indexer-password="adminpassword" \
  dashboard-username="admin" \
  dashboard-password="adminpassword"

echo "Storing API secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv put secret/dev/github/wazuh \
  api-username="wazuh" \
  api-password="wazuhpassword"

echo "Storing root CA secrets..."
# Check if certificate files exist in the traditional location
if [ -f "../wazuh-certs/root-ca.pem" ] && [ -f "../wazuh-certs/root-ca-key.pem" ]; then
  echo "Using certificate files from ../wazuh-certs/"
  # First, copy the certificate files to the pod
  kubectl cp ../wazuh-certs/root-ca.pem vault/$VAULT_POD:/tmp/root-ca.pem
  kubectl cp ../wazuh-certs/root-ca-key.pem vault/$VAULT_POD:/tmp/root-ca-key.pem

  # Then store them in Vault
  kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv put secret/dev/github/wazuh/root-ca \
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
    kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv put secret/dev/github/wazuh/root-ca \
      "ca.crt=@/tmp/root-ca.pem" \
      "ca.key=@/tmp/root-ca-key.pem"
    
    # Clean up temporary files
    rm -f /tmp/ca.crt /tmp/ca.key
  else
    echo "Error: Neither certificate files in ../wazuh-certs/ nor cert-manager secret found."
    echo "Please ensure either:"
    echo "  1. Certificate files exist in ../wazuh-certs/ directory, or"
    echo "  2. cert-manager is deployed with ca-key-pair secret"
    exit 1
  fi
fi

echo "Vault populated with secrets successfully!"

# Verify the secrets were created
echo "Verifying secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv list secret/dev/github/wazuh/
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/indexer
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/root-ca

echo "All secrets have been successfully stored and verified in Vault!"