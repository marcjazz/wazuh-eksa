resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.9.0"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  dependency_update = true
  skip_crds         = true
  replace           = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  wait            = true
  atomic          = true
  cleanup_on_fail = true
}