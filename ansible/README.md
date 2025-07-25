# Create EKS-A Cluster on an Existing VM with Ansible

This playbook configures an existing VM and creates an EKS Anywhere cluster inside it using the Docker provider.

## Prerequisites

- Ansible 2.10+
- An existing VM with SSH access.
- An SSH key pair to connect to the VM.

## Usage

1.  **Update the inventory:**

    Modify `inventory.yaml` with your VM's connection details (IP address, user, and SSH key path).

2.  **Run the playbook:**

    ```bash
    ansible-playbook -i inventory.yaml create_eksa_cluster.yaml
    ```

    The playbook will:
    - Connect to the specified VM.
    - Install Docker, `eksctl`, and `eksctl-anywhere`.
    - Generate an EKS-A cluster configuration file.
    - Create the EKS-A cluster.