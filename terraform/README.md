# terraform-eks-a: Minimal Docker/Dev-Only Terraform Configuration
 
This directory contains a minimal Terraform configuration for local (Docker-based) Kubernetes development.
 
- **No AWS-specific modules, resources, or settings are present.**
- Uses the local backend for state.
- The Kubernetes and Helm providers are configured.
- Installs ArgoCD with default and local-dev values.
 
## Usage
 
1. Ensure you have a local Kubernetes cluster running (e.g., kind, k3d, Docker Desktop).
2. Ensure your kubeconfig is at `~/.kube/config` or update `provider.tf` as needed.
3. Initialize and apply:
 
   ```sh
   cd terraform-eksa
   terraform init
   terraform apply
   ```
 
This configuration is intentionally AWS-free and is designed for rapid, local development and testing.
