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

This will deploy Argo CD to the EKS-A cluster.
