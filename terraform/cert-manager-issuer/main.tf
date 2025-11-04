provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

variable "email" {
  description = "Email address for Let's Encrypt ACME registration"
  type        = string
}

variable "dns_zone" {
  description = "DNS zone for Cloudflare"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

# Secret Cloudflare
resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  type = "Opaque"
}

# ClusterIssuer for Let's Encrypt DNS-01 via Cloudflare
resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = {
      name = "letsencrypt-dns"
    }
    spec       = {
      acme = {
        email               = var.email
        privateKeySecretRef = {
          name = "letsencrypt-dns-account-key"
        }
        server = "https://acme-v02.api.letsencrypt.org/directory"
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  key  = "api-token"
                  name = "cloudflare-api-token-secret"
                }
                email = var.email
              }
            }
          }
        ]
      }
    }
  }

  # Cette configuration s'assure que la ressource ne sera pas détruite par erreur
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    kubernetes_secret.cloudflare_api_token
  ]
}
