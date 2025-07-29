# Generate a private key for the CA
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate a self-signed CA certificate
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "EKS-A Development CA"
    organization = "EKS-A"
  }

  validity_period_hours = 87600  # 10 years
  early_renewal_hours   = 720    # 30 days

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# Store the CA certificate and key in a Kubernetes secret
resource "kubernetes_secret" "ca_key_pair" {
  metadata {
    name      = "ca-key-pair"
    namespace = "cert-manager"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.ca_cert.cert_pem
    "tls.key" = tls_private_key.ca_key.private_key_pem
  }

  type = "kubernetes.io/tls"
}