###############################################
# ClusterIssuer Let's Encrypt (DNS-01, Cloudflare)
###############################################

###############################################
# ClusterIssuer Let's Encrypt (DNS-01, Cloudflare)
###############################################
resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns"
    }
    spec = {
      acme = {
        email  = var.email
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "letsencrypt-dns-account-key"
        }

        solvers = [
          {
            selector = {
              dnsZones = [var.dns_zone]
            }
            dns01 = {
              cloudflare = {
                email = var.email
                apiTokenSecretRef = {
                  name = kubernetes_secret.cloudflare_api_token.metadata[0].name
                  key  = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret.cloudflare_api_token,
    null_resource.wait_for_certmanager_crds
  ]
}
###############################################
# Output de contrôle
###############################################

output "clusterissuer_status" {
  value = {
    name       = kubernetes_manifest.clusterissuer_letsencrypt.manifest["metadata"]["name"]
    email      = var.email
    dns_zone   = var.dns_zone
    secret_ref = "letsencrypt-dns"
  }
  description = "ClusterIssuer Let's Encrypt DNS-01 (Cloudflare)"
}
