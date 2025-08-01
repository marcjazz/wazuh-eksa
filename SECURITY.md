# Security Best Practices

This document outlines security best practices for handling sensitive data in the Wazuh EKS-A project.

## Overview

This project uses several security mechanisms to protect sensitive data:
- External Secrets Operator for Kubernetes secrets management
- HashiCorp Vault for centralized secret storage
- Environment-specific configuration templates
- Git ignore patterns to prevent credential leakage

## Sensitive Data Handling

### 1. Terraform Variables

**❌ Never commit actual credentials:**
```hcl
# terraform/eksa-dev.tfvars - DON'T DO THIS
wazuh_helm_username = "actual-username"
wazuh_helm_password = "actual-password"
```

**✅ Use placeholder values and template files:**
```hcl
# terraform/eksa-dev.tfvars - Use placeholders
wazuh_helm_username = "REPLACE_WITH_YOUR_USERNAME"
wazuh_helm_password = "REPLACE_WITH_YOUR_PASSWORD"
```

**Setup Instructions:**
1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
2. Replace placeholder values with actual credentials
3. The `.gitignore` file ensures `*.tfvars` files are not committed

### 2. Ansible Configuration

**❌ Never commit actual SSH keys or IP addresses:**
```yaml
# ansible/inventory.yaml - DON'T DO THIS
ansible_host: 192.168.1.100
ansible_ssh_private_key_file: ~/.ssh/production_key
```

**✅ Use placeholder values:**
```yaml
# ansible/inventory.yaml - Use placeholders
ansible_host: REPLACE_WITH_YOUR_VM_IP
ansible_ssh_private_key_file: REPLACE_WITH_YOUR_SSH_KEY_PATH
```

**Setup Instructions:**
1. Copy `ansible/inventory.yaml.example` to `ansible/inventory.yaml`
2. Replace placeholder values with actual infrastructure details
3. Ensure SSH keys are stored securely and not committed to git

### 3. Kubernetes Secrets

**❌ Never use hardcoded secrets:**
```yaml
# DON'T DO THIS
data:
  token: cm9vdC10b2tlbg==  # hardcoded base64 token
```

**✅ Use External Secrets Operator:**
```yaml
# Use External Secrets to fetch from Vault
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: wazuh-indexer-external-secret
spec:
  secretStoreRef:
    name: wazuh-secret-store
    kind: ClusterSecretStore
```

### 4. Vault Token Management

For development environments, create the vault token secret manually:
```bash
# Set your vault token as an environment variable
export VAULT_TOKEN="your-actual-vault-token"

# Create the secret in Kubernetes
kubectl create secret generic vault-token \
  --from-literal=token=$VAULT_TOKEN \
  -n external-secrets
```

For production environments, consider:
- Vault Agent for automatic token renewal
- Kubernetes Service Account Token Volume Projection
- External Secrets Operator with secure backend authentication

## File Patterns to Protect

The `.gitignore` file is configured to exclude:

### Terraform Files
- `*.tfvars` (except `*.tfvars.example`)
- `*.tfstate` and `*.tfstate.*`

### Credentials and Secrets
- `*.secret`, `*.token`
- `.env` files (except `.env.example`)
- `secrets/` directory

### SSH Keys and Certificates
- `*.pem`, `*.key`, `id_rsa*`
- `*.crt`, `*.cert`, `*.p12`, `*.pfx`
- `*-certs/` directories

### Backup and Temporary Files
- `*.bak`, `*.backup`, `*.orig`
- `*.log`, `logs/`

## Environment Setup Checklist

Before deploying, ensure:

- [ ] All `*.tfvars.example` files are copied to `*.tfvars` with real values
- [ ] All `*.yaml.example` files are copied with actual configuration
- [ ] SSH keys are properly secured and not in the repository
- [ ] Vault tokens are created via environment variables or secure methods
- [ ] `.gitignore` patterns are up to date
- [ ] No sensitive data is committed to version control

## Security Validation

Run these commands to check for potential security issues:

```bash
# Check for potential secrets in git history
git log --all --full-history -- "*.tfvars"

# Search for potential hardcoded credentials
grep -r "password\|secret\|key" --include="*.yaml" --include="*.tf" .

# Verify .gitignore is working
git status --ignored
```

## Incident Response

If sensitive data is accidentally committed:

1. **Immediately rotate the exposed credentials**
2. **Remove the sensitive data from git history:**
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch path/to/sensitive/file' \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push to update remote repository**
4. **Notify team members to re-clone the repository**

## Additional Resources

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [HashiCorp Vault Best Practices](https://learn.hashicorp.com/vault)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Git Security Best Practices](https://docs.github.com/en/code-security)