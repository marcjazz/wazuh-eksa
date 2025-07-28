resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}
