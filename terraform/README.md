# Terraform Configuration for EKS-A

This Terraform configuration is used to deploy applications to the EKS-A cluster created by the Ansible playbook.

## Prerequisites

- An EKS-A cluster must be running and accessible. You can create one using the Ansible playbook in the `ansible` directory.
- The `kubeconfig` file for the EKS-A cluster must be available at the path specified in the `eksa-dev.tfvars` file (by default, `~/.kube/config`).

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Apply the configuration:**
   ```bash
   terraform apply -var-file=eksa-dev.tfvars
   ```

This will deploy Argo CD, the External Secrets Operator, and cert-manager to the EKS-A cluster.

## External Secrets Operator

The External Secrets Operator is deployed as part of this Terraform configuration to manage secrets in the cluster. It provides the necessary Custom Resource Definitions (CRDs) for ExternalSecret resources used by the applications.

For more detailed information about the External Secrets Operator implementation, see [EXTERNAL_SECRETS.md](EXTERNAL_SECRETS.md).

## Certificate Management with cert-manager

This project uses cert-manager for certificate management. cert-manager is a powerful tool that automates the management and issuance of TLS certificates.

### Issuers

The following ClusterIssuers are configured:

1. **selfsigned-issuer**: Creates self-signed certificates for development and testing
2. **ca-issuer**: Uses a self-signed CA to create certificates
3. **letsencrypt-staging**: Uses Let's Encrypt staging environment for testing
4. **letsencrypt-production**: Uses Let's Encrypt production environment for real certificates

### Integration with External Secrets

The certificate management system is integrated with the External Secrets Operator:

1. **Root CA Certificate**: Instead of storing static CA certificates in External Secrets, we use cert-manager to generate and manage them
2. **Application Certificates**: Applications can request certificates directly from cert-manager
3. **Backward Compatibility**: For environments where cert-manager is not available, External Secrets can still provide static certificates

### Usage

To request a certificate, create a Certificate resource:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: wazuh
spec:
  secretName: example-com-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: example.com
  dnsNames:
  - example.com
  - www.example.com
```

3. **Login to Argo CD (gRPC-Web)**

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   argocd login localhost:8080 \
     --username <username> \
     --password <password> \
     --grpc-web
   ```
