#!/bin/bash

# Script to populate Vault secrets using kubectl exec
# This avoids the need to install Vault CLI locally

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
# First, copy the certificate files to the pod
kubectl cp ../wazuh-certs/root-ca.pem vault/$VAULT_POD:/tmp/root-ca.pem
kubectl cp ../wazuh-certs/root-ca-key.pem vault/$VAULT_POD:/tmp/root-ca-key.pem

# Then store them in Vault
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv put secret/dev/github/wazuh/root-ca \
  "ca.crt=@/tmp/root-ca.pem" \
  "ca.key=@/tmp/root-ca-key.pem"

echo "Vault populated with secrets successfully!"

# Verify the secrets were created
echo "Verifying secrets..."
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv list secret/dev/github/wazuh/
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/indexer
kubectl exec -n vault $VAULT_POD -- env VAULT_ADDR='http://127.0.0.1:8200' VAULT_TOKEN='root-token' vault kv get secret/dev/github/wazuh/root-ca