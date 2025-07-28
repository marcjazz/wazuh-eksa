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
variable "wazuh_api_username" {
  description = "Wazuh API username"
  type        = string
}

variable "wazuh_api_password" {
  description = "Wazuh API password"
  type        = string
  sensitive   = true
}