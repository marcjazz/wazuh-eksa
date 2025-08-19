# HashiCorp Vault Setup for Wazuh EKSA

This directory contains the configuration files for setting up HashiCorp Vault as the secret management solution for the Wazuh EKSA deployment.

## Prerequisites

- Kubernetes cluster
- kubectl configured to access the cluster
- No Vault CLI installation required (all operations use kubectl exec)

## Deployment

1. Deploy Vault to the cluster using the unified approach:
   ```bash
   ./unified-vault-deploy.sh
   ```

## Secure Secret Management

### Security Improvements

The unified script has been updated to avoid hardcoding secrets:

1. **unified-vault-deploy.sh** now accepts secrets as environment variables instead of hardcoding them

### Required Environment Variables

When running `unified-vault-deploy.sh`, the following environment variables must be set:

- `VAULT_TOKEN` - Vault root token
- `INDEXER_PASSWORD` - Indexer password
- `DASHBOARD_PASSWORD` - Dashboard password
- `API_PASSWORD` - API password

### Example Usage

For development with default values:
```bash
VAULT_TOKEN='root-token' INDEXER_PASSWORD='adminpassword' DASHBOARD_PASSWORD='adminpassword' API_PASSWORD='wazuhpassword' ./unified-vault-deploy.sh
```

For production, use a secure method to pass secrets:
```bash
VAULT_TOKEN='your-secure-token' INDEXER_PASSWORD='your-secure-password' DASHBOARD_PASSWORD='your-secure-password' API_PASSWORD='your-secure-password' ./unified-vault-deploy.sh
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

The External Secrets Operator is configured to use Vault as the secret store. The `ClusterSecretStore` resource in `apps/infrastructure/secrets/secrets-store.yaml` references Vault as the provider.

A Kubernetes secret `vault-token` in the `external-secrets` namespace contains the Vault token for authentication.
