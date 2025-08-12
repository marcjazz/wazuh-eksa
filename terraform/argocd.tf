resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  
}

resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.9.0"
  namespace        = "argocd"
  create_namespace = false
  dependency_update = true
  skip_crds         = true
  replace           = true
  
  atomic          = true
  cleanup_on_fail = true
}