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
        email               = var.email
        server              = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-dns"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = kubernetes_secret.cloudflare_api_token.metadata[0].name
                  key  = "api-token"
                }
              }
            }
            selector = {
              dnsZones = [var.dns_zone]
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
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
