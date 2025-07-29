# External Secrets Operator Installation

## Problem
The Kubernetes API could not find `external-secrets.io/ExternalSecret` for requested resource `wazuh/wazuh-api-external-secret`. This error occurs because the External Secrets Operator is not installed on the cluster, which means the required Custom Resource Definitions (CRDs) are missing.

## Solution
The External Secrets Operator has been added to the Terraform configuration in [main.tf](main.tf) as a Helm release:

```hcl
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.9.11"
  namespace        = "external-secrets"
  create_namespace = true
  dependency_update = true
  skip_crds         = false
  replace           = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  wait            = true
  atomic          = true
  cleanup_on_fail = true
}
```

Additionally, a ServiceAccount named `external-secrets-sa` has been created in the `external-secrets` namespace. The ServiceAccount is defined in [external-secrets.tf](external-secrets.tf) along with the necessary RBAC permissions.

For local development with EKS-A Docker provider, the ClusterSecretStore has been configured to use a fake provider instead of AWS Secrets Manager. This allows the External Secrets Operator to function without requiring AWS credentials.

## Key Configuration Points

1. **CRD Installation**: The `installCRDs` setting is set to `true` to ensure all necessary CRDs are installed
2. **Namespace**: The operator is installed in the `external-secrets` namespace
3. **Dependencies**: The eksa module depends on this release to ensure proper installation order
4. **Version**: Using version 0.9.11 of the external-secrets chart
5. **ServiceAccount**: A dedicated ServiceAccount `external-secrets-sa` is created
6. **Local Development**: For EKS-A Docker provider, a fake provider is used instead of AWS

## Configuration for Production
For production deployments using AWS EKS, you would need to:
1. Update the ClusterSecretStore to use AWS Secrets Manager provider
2. Configure the ServiceAccount with IAM role annotations
3. Create the necessary IAM role with appropriate permissions

Note: This project also includes cert-manager for certificate management. For more information, see [README.md](README.md).

## Integration with cert-manager

The External Secrets Operator is integrated with cert-manager for enhanced certificate management:

1. **Root CA Management**: Instead of storing static CA certificates in External Secrets, we use cert-manager to generate and manage them
2. **Application Certificates**: Applications can request certificates directly from cert-manager
3. **Backward Compatibility**: For environments where cert-manager is not available, External Secrets can still provide static certificates

## Verification
After applying the Terraform configuration, you can verify the installation with:

```bash
# Check if the CRDs are installed
kubectl get crd | grep external-secrets

# Check if the External Secrets Operator is running
kubectl get pods -n external-secrets

# Check if the ServiceAccount exists
kubectl get serviceaccount external-secrets-sa -n external-secrets

# Check if the ClusterSecretStore is ready
kubectl get clustersecretstore wazuh-secret-store

# Check if the ExternalSecret resources can be accessed
kubectl get externalsecret -n wazuh
```

## Dependencies
The solution depends on:
- Kubernetes cluster access
- Helm provider for Terraform
- Internet access to download the Helm chart from the external-secrets repository