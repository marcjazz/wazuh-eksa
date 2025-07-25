resource "kubernetes_namespace" "wazuh_eksa" {
  metadata {
    name = "wazuh-eksa"
  }
}
resource "helm_release" "wazuh" {
  name       = "wazuh"
  repository = "https://wazuh.github.io/wazuh-helm/"
  chart      = "wazuh"
  namespace  = kubernetes_namespace.wazuh_eksa.metadata[0].name
  version    = "4.3.0" # Replace with your desired chart version

  values = [
    file("${path.module}/../charts/wazuh/values-eksa.yaml"),
    yamlencode({
      wazuh = {
        api = {
          username = var.wazuh_api_username
          password = var.wazuh_api_password
        }
      }
    })
  ]
}