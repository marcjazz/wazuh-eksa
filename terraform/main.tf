resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.5" # Specify a recent, stable version

  values = [
    file("${path.module}/argocd/values.yaml"),
    file("${path.module}/argocd/values-eksa.yaml")
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}