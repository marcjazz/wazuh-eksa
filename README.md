# Wazuh EKSA Deployment

This repository contains the necessary Ansible configurations to deploy Wazuh on an EKS Anywhere (EKSA) cluster with HashiCorp Vault for secret management.

## Architecture Overview

The deployment is managed entirely by Ansible and consists of:
1. **EKS-A Cluster** - Created using Ansible on a virtual machine.
2. **Infrastructure Components** - Deployed via Ansible, including:
    - HashiCorp Vault for secrets management.
    - External Secrets Operator to bridge Kubernetes secrets with Vault.
    - cert-manager for certificate management.
    - local-path-provisioner for storage.
3. **Wazuh Components** - Deployed via an Ansible role that uses the official Wazuh Helm chart.

## Prerequisites

- A virtual machine (e.g., created with Multipass or another virtualization platform).
- SSH access to the VM.
- Ansible installed on your local machine.
- `kubectl` installed on your local machine to interact with the cluster after deployment.

## Deployment Process

The entire deployment process is automated with a single Ansible playbook.

### 1. Configure Inventory

First, you need to provide the details of your target virtual machine to Ansible.

```bash
# 1. Copy the example inventory file
cp ansible/inventory.yaml.example ansible/inventory.yaml

# 2. Edit ansible/inventory.yaml with your VM's SSH details.
# You must also provide the necessary credentials for the Wazuh Helm repository.
#
# example:
# all:
#  hosts:
#    eksa_vm:
#      ansible_host: 192.168.64.2
#      ansible_user: multipass
#      ansible_ssh_private_key_file: /path/to/your/ssh/key
#  vars:
#    wazuh_environment: dev
#    wazuh_helm_username: your_helm_username
#    wazuh_helm_password: your_helm_password
```

### 2. Run the Ansible Playbook

Run the main playbook from within the `ansible` directory. This will set up the VM, create the EKS-A cluster, and deploy all the necessary components and Wazuh itself.

```bash
cd ansible
ansible-playbook -i inventory.yaml playbook.yaml
```

### 3. Accessing the Cluster

Once the playbook finishes, the `kubeconfig` file will be located on the VM at `~/.kube/config`. You can copy this file to your local machine to interact with the cluster using `kubectl`.

The playbook handles the entire setup, from cluster creation to application deployment, providing a streamlined, GitOps-friendly approach without the need for Terraform or ArgoCD.
