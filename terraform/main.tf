# Note: Helm releases for cert-manager, external-secrets, and local-path-provisioner
# have been moved to be managed by ArgoCD through manifests.
# This file now only contains the argocd_apps module that deploys ArgoCD applications.
module "argocd_apps" {
  source     = "blackbird-cloud/deployment/helm"
  depends_on = [helm_release.argo_cd] # Only argo_cd is still managed by Terraform
  version    = "~> 1.0"

  name             = "argocd_apps"
  namespace        = "argocd"
  create_namespace = false

  repository    = "https://bedag.github.io/helm-charts"
  chart         = "raw"
  chart_version = "2.0.0"

  values = [
    templatefile("${path.module}/files/argocd-apps.yaml", {
      environment         = var.environment
      target_revision     = var.target_revision
      wazuh_helm_username = var.wazuh_helm_username
      wazuh_helm_password = var.wazuh_helm_password
    })
  ]

  cleanup_on_fail = true
}
