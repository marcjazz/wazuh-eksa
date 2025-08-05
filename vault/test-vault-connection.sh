#!/bin/bash

# Test script to verify Vault connectivity and secret access
# This version uses kubectl exec instead of requiring Vault CLI locally

echo "Testing Vault connectivity..."

# Check if Vault pod is running
echo "Checking Vault pod status..."
kubectl get pods -n vault

# Get the Vault pod name
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
if [ -z "$VAULT_POD" ]; then
    echo "Error: No Vault pod found"
    exit 1
fi

echo "Using Vault pod: $VAULT_POD"

# Check Vault status using kubectl exec
echo "Checking Vault status..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault status

# List secrets engines using kubectl exec
echo "Listing secrets engines..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault secrets list

# Test reading secrets using kubectl exec
echo "Testing secret access..."

echo "Reading indexer secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/indexer

echo "Reading API secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh

echo "Reading root CA secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/root-ca

echo "Vault connectivity test completed!"