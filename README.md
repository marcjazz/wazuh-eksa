# Wazuh EKSA Deployment

This repository contains the necessary configurations and scripts to deploy Wazuh on an EKS Anywhere (EKSA) cluster with HashiCorp Vault for secret management.

## Architecture Overview

The deployment consists of:
1. **EKS-A Cluster** - Created using Ansible on a virtual machine
2. **HashiCorp Vault** - Deployed as a secrets management solution
3. **External Secrets Operator** - Bridges Kubernetes secrets with Vault
4. **Wazuh Components** - Deployed using ArgoCD and Terraform

## Prerequisites

- Multipass VM or similar virtualization platform
- SSH access to the VM
- Ansible installed locally
- Terraform installed locally
- kubectl configured to access the cluster (after deployment)

## Deployment Process

### 1. Set up the EKS-A Cluster

First, you need to create and configure a virtual machine and deploy the EKS-A cluster:

```bash
# 1. Copy and configure the inventory file
cp ansible/inventory.yaml.example ansible/inventory.yaml
# Edit ansible/inventory.yaml with your VM details

# 2. Run the Ansible playbook to set up the EKS-A cluster
cd ansible
ansible-playbook -i inventory.yaml playbook.yaml
cd ..

# 3. Configure kubectl to access the cluster
# This step depends on your specific setup but typically involves:
# - Copying the kubeconfig from the VM
# - Setting the KUBECONFIG environment variable
```

### 2. Deploy HashiCorp Vault

After the E
