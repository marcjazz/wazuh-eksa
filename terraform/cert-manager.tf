# Wait for cert-manager to be ready before creating issuers
resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]
  create_duration = "60s"
}

# Self-signed Issuer for development and testing
resource "kubernetes_manifest" "selfsigned_issuer" {
  depends_on = [time_sleep.wait_for_cert_manager]
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned-issuer"
    }
    spec = {
      selfSigned = {}
    }
  }
}

# CA Issuer using the self-signed issuer to create a CA
resource "kubernetes_manifest" "ca_issuer" {
  depends_on = [time_sleep.wait_for_cert_manager]
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "ca-issuer"
    }
    spec = {
      ca = {
        secretName = "ca-key-pair"
      }
    }
  }
}

# Let's Encrypt staging issuer for testing (HTTP01 challenges)
resource "kubernetes_manifest" "letsencrypt_staging" {
  depends_on = [time_sleep.wait_for_cert_manager]
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-staging-private-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

# Let's Encrypt production issuer (HTTP01 challenges)
resource "kubernetes_manifest" "letsencrypt_production" {
  depends_on = [time_sleep.wait_for_cert_manager]
  
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-production"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-production-private-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}