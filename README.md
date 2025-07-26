# EKS-A Wazuh Deployment

This project provides a comprehensive solution to automate the deployment of a Wazuh cluster on Amazon EKS Anywhere (EKS-A) running on a virtual machine. It leverages Ansible for infrastructure setup, Terraform for deploying applications on Kubernetes, and Helm for packaging the Wazuh application.

## Architecture

The deployment process is orchestrated as follows:

1.  **Ansible**: Sets up an EKS-A cluster on a pre-existing virtual machine using the Docker provider. It handles the installation of all necessary dependencies like Docker, `eksctl`, and `eksctl-anywhere`.
2.  **Terraform**: Once the Kubernetes cluster is running, Terraform is used to deploy cluster-level applications. It is configured to install ArgoCD, which can be used for continuous delivery of other applications.
3.  **Helm**: The Wazuh deployment itself is managed via a Helm chart, allowing for configurable and repeatable installations.

## Components

-   `ansible/`: Contains playbooks to create the EKS-A cluster.
-   `terraform/`: Includes Terraform configurations for deploying ArgoCD.
-   `charts/`: Holds the Helm chart for deploying Wazuh.
-   `deploy/`: Contains Kubernetes manifests for secrets management, including integration with a secrets store.

## Prerequisites

-   An existing VM (Ubuntu/Debian recommended) with SSH access.
-   Ansible 2.10+ installed on your local machine.
-   Terraform installed on your local machine.
-   An SSH key pair for accessing the VM.

## Deployment Steps

### 1. Create the EKS-A Cluster with Ansible

First, configure your VM details and run the Ansible playbook to create the cluster.

-   **Configure Inventory**: Update [`ansible/inventory.yaml`](ansible/inventory.yaml:1) with your VM's IP address, SSH user, and the path to your private SSH key.

-   **Run the Playbook**:
    ```bash
    ansible-playbook -i ansible/inventory.yaml ansible/create_eksa_cluster.yaml
    ```
    This will connect to the VM, install dependencies, and create the EKS-A cluster. After completion, a `kubeconfig` file will be generated in the `ansible/` directory.

### 2. Deploy ArgoCD with Terraform

Next, use Terraform to deploy ArgoCD onto your new cluster.

-   **Configure Kubeconfig**: Ensure your `KUBECONFIG` environment variable points to the generated kubeconfig file or copy it to `~/.kube/config`.

-   **Initialize and Apply**:
    ```sh
    cd terraform
    terraform init
    terraform apply
    ```

### 3. Deploy Wazuh

The Helm chart for Wazuh can be deployed using standard Helm commands.

-   **Customize Values**: Modify the [`charts/wazuh/values-eksa.yaml`](charts/wazuh/values-eksa.yaml:1) file to customize your Wazuh deployment.

-   **Deploy the Chart**:
    ```sh
    helm install wazuh ./charts/wazuh -f ./charts/wazuh/values-eksa.yaml --namespace wazuh --create-namespace
    ```

## Configuration

-   **Ansible**: [`ansible/inventory.yaml`](ansible/inventory.yaml:1) - Main inventory for target hosts.
-   **Terraform**: [`terraform/eksa-dev.tfvars`](terraform/eksa-dev.tfvars:1) - Variables for the Terraform deployment.
-   **Wazuh Helm Chart**: [`charts/wazuh/values-eksa.yaml`](charts/wazuh/values-eksa.yaml:1) - Overrides for the Wazuh deployment on EKS-A.