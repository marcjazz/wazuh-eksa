
data "kubernetes_secret" "argocd_redis" {
  metadata {
    name      = "argocd-redis"
    namespace = kubernetes_namespace.argocd.metadata.0.name
  }
}