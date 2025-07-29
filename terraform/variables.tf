variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "kubeconfig" {
  description = "Path to the kubeconfig file for the EKS cluster"
  type        = string
}
variable "target_revision" {
  description = "The target revision for the ArgoCD applications"
  type        = string
  default     = "develop"
}
variable "wazuh_helm_username" {
  description = "Wazuh Helm repository username"
  type        = string
}

variable "wazuh_helm_password" {
  description = "Wazuh Helm repository password"
  type        = string
  sensitive   = true
}


variable "cert_manager_email" {
  description = "Email address for cert-manager Let's Encrypt issuers"
  type        = string
  default     = "admin@example.com"
}