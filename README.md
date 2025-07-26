# EKS-A Cluster with Ansible and Terraform

This project automates the deployment of an EKS Anywhere (EKS-A) cluster on a Multipass VM using Ansible, and then deploys applications to the cluster using Terraform.

## Workflow

1.  **Provision EKS-A Cluster:** The Ansible playbook in the `ansible` directory sets up the Multipass VM, installs all necessary dependencies, and creates an EKS-A cluster.
2.  **Deploy Applications:** The Terraform configuration in the `terraform` directory deploys Argo CD to the newly created EKS-A cluster.

## Instructions

1.  **Create and configure the EKS-A cluster:**
    -   Follow the instructions in `ansible/README.md` to run the Ansible playbook.

2.  **Deploy Argo CD to the cluster:**
    -   Once the cluster is running, follow the instructions in `terraform/README.md` to apply the Terraform configuration.

For more detailed information, refer to the `README.md` files in the `ansible` and `terraform` directories.