resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.9.11"
  namespace        = "external-secrets"
  create_namespace = true
  dependency_update = true
  skip_crds         = false
  replace           = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  wait            = true
  atomic          = true
  cleanup_on_fail = true
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.14.0"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name
  create_namespace = false
  dependency_update = true
  skip_crds         = false
  replace           = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"
  }

  wait            = true
  atomic          = true
  cleanup_on_fail = true
}

# Add local-path-provisioner via Helm
resource "helm_release" "local_path_provisioner" {
  name             = "local-path-provisioner"
  repository       = "https://charts.containeroo.ch"
  chart            = "local-path-provisioner"
  version          = "0.0.33"
  namespace        = "local-path-storage"
  create_namespace = true
  dependency_update = true
  skip_crds         = false
  replace           = true

  set {
    name  = "storageClass.create"
    value = "true"
  }

  set {
    name  = "storageClass.defaultClass"
    value = "true"
  }

  set {
    name  = "storageClass.name"
    value = "local-path"
  }

  set {
    name  = "storageClass.reclaimPolicy"
    value = "Delete"
  }

  wait            = true
  atomic          = true
  cleanup_on_fail = true
}

module "eksa" {
  source  = "blackbird-cloud/deployment/helm"
  depends_on = [helm_release.argo_cd, helm_release.external_secrets, helm_release.cert_manager, helm_release.local_path_provisioner]
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
