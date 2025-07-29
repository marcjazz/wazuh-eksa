# HashiCorp Vault Setup for Wazuh EKSA

This directory contains the configuration files for setting up HashiCorp Vault as the secret management solution for the Wazuh EKSA deployment.

## Prerequisites

- Kubernetes cluster
- kubectl configured to access the cluster
- Vault CLI installed (optional, for manual operations)

## Deployment

1. Deploy Vault to the cluster:
   ```bash
   kubectl apply -f vault-deployment.yaml
   ```

2. Wait for Vault to be ready:
   ```bash
   kubectl wait --for=condition=available deployment/vault -n vault --timeout=60s
   ```

3. Create the Vault token secret:
   ```bash
   kubectl apply -f ../apps/eksa-dev/vault-token-secret.yaml
   ```

4. Apply the ClusterSecretStore configuration:
   ```bash
   kubectl apply -f ../apps/eksa-dev/secrets-store.yaml
   ```

5. Populate Vault with secrets:
   ```bash
   ./populate-vault.sh
   ```

## Vault Configuration

Vault is deployed in development mode with a root token `root-token`. The Vault image is pulled from Docker Hub (hashicorp/vault:1.15.0). In a production environment, you should:

1. Use a production-ready Vault deployment with proper storage backend
2. Implement proper authentication methods (AppRole, Kubernetes auth, etc.)
3. Use TLS encryption for all communications
4. Implement proper secret rotation policies

## Secret Paths

The following secrets are stored in Vault:

- `secret/dev/github/wazuh/indexer` - Indexer and dashboard credentials
- `secret/dev/github/wazuh` - Wazuh API credentials
- `secret/dev/github/wazuh/root-ca` - Root CA certificate and key

## Integration with External Secrets Operator

The External Secrets Operator is configured to use Vault as the secret store. The `ClusterSecretStore` resource in `apps/eksa-dev/secrets-store.yaml` references Vault as the provider.

A Kubernetes secret `vault-token` in the `external-secrets` namespace contains the Vault token for authentication.