output "cert_manager_status" {
  description = "Namespace et ClusterIssuer"
  value = {
    namespace       = kubernetes_namespace.cert_manager.metadata[0].name
    cluster_issuer  = "letsencrypt-dns"
    cloudflare_secret = kubernetes_secret.cloudflare_api_token.metadata[0].name
  }
}
