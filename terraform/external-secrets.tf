resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets"
  }
}

resource "kubernetes_cluster_role_binding" "external_secrets_sa_binding" {
  metadata {
    name = "external-secrets-sa-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_secrets_sa.metadata[0].name
    namespace = kubernetes_service_account.external_secrets_sa.metadata[0].namespace
  }
}

# Additional RBAC permissions needed for External Secrets Operator to work with AWS JWT auth
resource "kubernetes_role" "external_secrets_jwt_role" {
  metadata {
    name      = "external-secrets-jwt-role"
    namespace = "external-secrets"
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts/token"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "external_secrets_jwt_role_binding" {
  metadata {
    name      = "external-secrets-jwt-role-binding"
    namespace = "external-secrets"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.external_secrets_jwt_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_secrets_sa.metadata[0].name
    namespace = kubernetes_service_account.external_secrets_sa.metadata[0].namespace
  }
}