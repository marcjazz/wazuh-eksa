provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig)
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kubeconfig)
  }
}
