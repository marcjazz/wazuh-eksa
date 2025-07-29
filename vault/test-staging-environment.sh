#!/bin/bash

# Comprehensive test script for the staging environment
# This script verifies that Vault is properly integrated with External Secrets Operator

echo "=== Wazuh EKSA Staging Environment Test ==="

# 1. Check if all required pods are running
echo "1. Checking pod status..."
echo "Vault pods:"
kubectl get pods -n vault

echo "External Secrets Operator pods:"
kubectl get pods -n external-secrets

echo "Wazuh pods:"
kubectl get pods -n wazuh

# 2. Check if Vault is properly configured
echo "2. Testing Vault connectivity..."
kubectl port-forward service/vault -n vault 8200:8200 &
PORT_FORWARD_PID=$!
sleep 5

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token'

echo "Vault status:"
vault status

echo "Secrets in Vault:"
vault kv get secret/dev/github/wazuh/indexer
vault kv get secret/dev/github/wazuh
vault kv get secret/dev/github/wazuh/root-ca

kill $PORT_FORWARD_PID

# 3. Check if ClusterSecretStore is properly configured
echo "3. Checking ClusterSecretStore configuration..."
kubectl get clustersecretstore wazuh-secret-store -o yaml

# 4. Check if ExternalSecrets are properly synced
echo "4. Checking ExternalSecrets status..."
kubectl get externalsecret -n wazuh

echo "Checking if secrets were created:"
kubectl get secret ext-wazuh-indexer-secrets -n wazuh -o yaml
kubectl get secret ext-wazuh-dashboard-secrets -n wazuh -o yaml
kubectl get secret ext-wazuh-api-credentials -n wazuh -o yaml
kubectl get secret ext-wazuh-root-ca-secrets -n wazuh -o yaml

# 5. Verify secret contents (without revealing sensitive data)
echo "5. Verifying secret structure..."
echo "Indexer secret keys:"
kubectl get secret ext-wazuh-indexer-secrets -n wazuh -o jsonpath='{.data}' | jq 'keys[]'

echo "Dashboard secret keys:"
kubectl get secret ext-wazuh-dashboard-secrets -n wazuh -o jsonpath='{.data}' | jq 'keys[]'

echo "API secret keys:"
kubectl get secret ext-wazuh-api-credentials -n wazuh -o jsonpath='{.data}' | jq 'keys[]'

echo "Root CA secret keys:"
kubectl get secret ext-wazuh-root-ca-secrets -n wazuh -o jsonpath='{.data}' | jq 'keys[]'

# 6. Check External Secrets Operator logs for errors
echo "6. Checking External Secrets Operator logs..."
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

echo "=== Test completed ==="