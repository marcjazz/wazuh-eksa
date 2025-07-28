module "eksa" {
  source  = "blackbird-cloud/deployment/helm"
  version = "~> 1.0"

  name             = "eksa"
  namespace        = "argocd"
  create_namespace = false

  repository    = "https://bedag.github.io/helm-charts"
  chart         = "raw"
  chart_version = "2.0.0"

  values = [
    templatefile("${path.module}/files/argocd-apps.yml", {
      environment    = var.environment
      target_revision = var.target_revision
    })
  ]

  cleanup_on_fail = true
  wait            = true
}