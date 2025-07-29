# HashiCorp Vault Migration Summary

This document summarizes the changes made to migrate from the fake secret provider to HashiCorp Vault for the Wazuh EKSA deployment.

## Overview

The previous implementation used a "fake" provider for External Secrets Operator, which stored secrets directly in the Kubernetes manifest. This approach is not suitable for production environments as it exposes sensitive data in version control.

This migration replaces the fake provider with HashiCorp Vault, providing a secure and scalable secret management solution.

## Changes Made

### 1. Vault Deployment

- Created `vault/vault-deployment.yaml` to deploy Vault in development mode
- Configured Vault with a root token for authentication
- Set up proper RBAC for Vault service account

### 2. Secret Migration

- Extracted all secrets from the fake provider configuration:
  - Indexer credentials (username/password)
  - Dashboard credentials (username/password)
  - Wazuh API credentials (username/password)
  - Root CA certificate and key
- Created `vault/populate-vault.sh` script to populate Vault with these secrets
- Organized secrets in Vault using a logical path structure

### 3. External Secrets Configuration

- Updated `apps/eksa-dev/secrets-store.yaml` to use Vault as the provider
- Created `apps/eksa-dev/vault-token-secret.yaml` to store the Vault authentication token
- Updated `apps/eksa-dev/kustomization.yaml` to include the new secret

### 4. Terraform Configuration

- Removed AWS-specific IAM role annotation from the External Secrets service account
- Removed the `external_secrets_iam_role_arn` variable from `terraform/variables.tf`
- Removed the AWS-specific variable from `terraform/eksa-dev.tfvars`

### 5. Documentation

- Created `vault/README.md` with detailed instructions for Vault setup and usage
- Updated the main `README.md` to reflect the Vault integration
- Created test scripts for verifying the setup

## Testing

Created comprehensive test scripts to verify the migration:

1. `vault/test-vault-connection.sh` - Tests basic Vault connectivity and secret access
2. `vault/test-staging-environment.sh` - Comprehensive test of the entire setup

## Security Considerations

The current implementation uses Vault in development mode with a static root token. For production use, consider:

1. Deploying Vault in production mode with proper storage backend
2. Implementing proper authentication methods (AppRole, Kubernetes auth, etc.)
3. Using TLS encryption for all communications
4. Implementing proper secret rotation policies
5. Using a more secure method for storing the Vault token (e.g., Kubernetes service account token or Vault agent)

## Rollback Procedure

To rollback to the previous fake provider configuration:

1. Replace `apps/eksa-dev/secrets-store.yaml` with the previous version
2. Remove `apps/eksa-dev/vault-token-secret.yaml` from `apps/eksa-dev/kustomization.yaml`
3. Restore the AWS-specific configurations in Terraform files
4. Remove the Vault deployment: `kubectl delete -f vault/vault-deployment.yaml`

## Next Steps

1. Test the setup in a staging environment using the provided test scripts
2. For production deployment, enhance the Vault setup with proper security measures
3. Consider implementing automatic secret rotation
4. Set up monitoring and alerting for the Vault deployment