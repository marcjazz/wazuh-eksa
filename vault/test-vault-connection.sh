#!/bin/bash

# Test script to verify Vault connectivity and secret access

echo "Testing Vault connectivity..."

# Check if Vault pod is running
echo "Checking Vault pod status..."
kubectl get pods -n vault

# Port forward to Vault
echo "Setting up port forward to Vault..."
kubectl port-forward service/vault -n vault 8200:8200 &
PORT_FORWARD_PID=$!

# Give port forward time to start
sleep 5

# Export Vault address and token
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token'

# Check Vault status
echo "Checking Vault status..."
vault status

# List secrets engines
echo "Listing secrets engines..."
vault secrets list

# Test reading secrets
echo "Testing secret access..."

echo "Reading indexer secrets..."
vault kv get secret/dev/github/wazuh/indexer

echo "Reading API secrets..."
vault kv get secret/dev/github/wazuh

echo "Reading root CA secrets..."
vault kv get secret/dev/github/wazuh/root-ca

# Clean up port forward
kill $PORT_FORWARD_PID

echo "Vault connectivity test completed!"