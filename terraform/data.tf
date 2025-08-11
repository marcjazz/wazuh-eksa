data "kubernetes_secret" "argocd_redis" {
  metadata {
    name      = "argocd-redis"
    namespace = "argocd"
  }
}