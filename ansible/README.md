# Ansible Playbook for EKS-A Cluster Creation

This Ansible playbook automates the process of setting up a virtual machine and deploying an EKS-A (EKS Anywhere) cluster on it.

## Prerequisites

- A running Multipass VM with SSH access.
- The VM's IP address, user, and SSH private key path must be configured in the `inventory.yaml` file.

## Usage

1. **Install Ansible:**
   Follow the official Ansible installation guide for your operating system.

2. **Run the playbook:**
   ```bash
   ansible-playbook -i inventory.yaml playbook.yaml
   ```

This will:
- Install necessary prerequisites on the VM.
- Install Docker.
- Install `eksctl-anywhere`.
- Create an EKS-A cluster based on the configuration in `roles/eksa/templates/cluster-config.yaml.j2`.

Once the playbook has finished, you can use the Terraform configuration in the `terraform` directory to deploy applications to the cluster.