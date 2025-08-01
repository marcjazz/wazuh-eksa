# EKS-A Cluster with Ansible and Terraform

This project automates the deployment of an EKS Anywhere (EKS-A) cluster on a Multipass VM using Ansible, and then deploys applications to the cluster using Terraform.

## Workflow

1.  **Provision EKS-A Cluster:** The Ansible playbook in the `ansible` directory sets up the Multipass VM, installs all necessary dependencies, and creates an EKS-A cluster.
2.  **Deploy Applications:** The Terraform configuration in the `terraform` directory deploys Argo CD, External Secrets Operator, and cert-manager to the newly created EKS-A cluster.

## Security Setup (IMPORTANT - Do this first!)

⚠️ **Before running any commands, you must configure sensitive data properly:**

1. **Configure Terraform variables:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform/terraform.tfvars with your actual credentials
   ```

2. **Configure Ansible inventory:**
   ```bash
   cp ansible/inventory.yaml.example ansible/inventory.yaml
   # Edit ansible/inventory.yaml with your actual VM details and SSH keys
   ```

3. **Set up Vault token (for Kubernetes secrets):**
   ```bash
   export VAULT_TOKEN="your-actual-vault-token"
   kubectl create secret generic vault-token --from-literal=token=$VAULT_TOKEN -n external-secrets
   ```

📖 **Read [SECURITY.md](SECURITY.md) for comprehensive security best practices.**

## Instructions

1.  **Create and configure the EKS-A cluster:**
    -   Follow the instructions in `ansible/README.md` to run the Ansible playbook.

2.  **Deploy Argo CD, External Secrets Operator, and cert-manager to the cluster:**
    -   Once the cluster is running, follow the instructions in `terraform/README.md` to apply the Terraform configuration.

For more detailed information, refer to the `README.md` files in the `ansible` and `terraform` directories.

## External Secrets Operator

This project uses External Secrets Operator with HashiCorp Vault to manage secrets instead of the fake provider. For more information about the implementation, see [vault/README.md](vault/README.md).

## Certificate Management

This project uses cert-manager for certificate management. For more information about the implementation, see [terraform/README.md](terraform/README.md).

## Directory Structure

- `ansible/` - Ansible playbooks for cluster creation and configuration
- `apps/` - Kubernetes manifests for applications
- `terraform/` - Terraform configurations for infrastructure and ArgoCD applications
- `vault/` - HashiCorp Vault configuration for secret management
- `wazuh-certs/` - Certificate files for Wazuh components