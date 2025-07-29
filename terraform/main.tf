module "eksa" {
  source  = "blackbird-cloud/deployment/helm"
  depends_on = [helm_release.argo_cd]
  version = "~> 1.0"

  name             = "eksa"
  namespace        = "argocd"
  create_namespace = false

  repository    = "https://bedag.github.io/helm-charts"
  chart         = "raw"
  chart_version = "2.0.0"

  values = [
    templatefile("${path.module}/files/argocd-apps.yaml", {
      environment         = var.environment
      target_revision     = var.target_revision
      wazuh_helm_username  = var.wazuh_helm_username
      wazuh_helm_password  = var.wazuh_helm_password
    })
  ]

  cleanup_on_fail = true
  wait            = true
}