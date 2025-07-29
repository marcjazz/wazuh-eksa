#!/bin/bash

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
kubectl wait --for=condition=available deployment/vault -n vault --timeout=60s

# If wait fails, let's check the pod status
if [ $? -ne 0 ]; then
    echo "Vault deployment failed to become available. Checking pod status..."
    kubectl get pods -n vault
    kubectl describe pod -n vault -l app.kubernetes.io/name=vault
    exit 1
fi

# Port forward to Vault
echo "Setting up port forward to Vault..."
kubectl port-forward service/vault -n vault 8200:8200 &
PORT_FORWARD_PID=$!

# Give port forward time to start
sleep 5

# Export Vault address and token
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token'

# Check if Vault is ready
echo "Checking Vault status..."
vault status

# Enable KV secrets engine
echo "Enabling KV secrets engine..."
vault secrets enable -path=secret kv-v2

# Store the indexer secrets
echo "Storing indexer secrets..."
vault kv put secret/dev/github/wazuh/indexer \
  indexer-username="admin" \
  indexer-password="adminpassword" \
  dashboard-username="admin" \
  dashboard-password="adminpassword"

# Store the API secrets
echo "Storing API secrets..."
vault kv put secret/dev/github/wazuh \
  api-username="wazuh" \
  api-password="wazuhpassword"

# Store the root CA secrets
echo "Storing root CA secrets..."
vault kv put secret/dev/github/wazuh/root-ca \
  "ca.crt=@../wazuh-certs/root-ca.pem" \
  "ca.key=@../wazuh-certs/root-ca-key.pem"

# Clean up port forward
kill $PORT_FORWARD_PID

echo "Vault populated with secrets successfully!"