###############################################
# Certificat de test ACME Let's Encrypt (DNS-01)
###############################################

resource "kubernetes_manifest" "certificate_test" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "tls-test-cert"
      namespace = "cert-manager"
    }
    spec = {
      secretName = "tls-test-cert-secret"
      issuerRef = {
        name = kubernetes_manifest.clusterissuer_letsencrypt.manifest["metadata"]["name"]
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "test.${var.dns_zone}"
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.clusterissuer_letsencrypt
  ]
}

###############################################
# Output de vérification
###############################################

output "certificate_test_status" {
  description = "Infos sur le certificat de test Let's Encrypt"
  value = {
    name       = kubernetes_manifest.certificate_test.manifest["metadata"]["name"]
    secret     = kubernetes_manifest.certificate_test.manifest["spec"]["secretName"]
    dns_name   = "test.${var.dns_zone}"
    issuer_ref = kubernetes_manifest.certificate_test.manifest["spec"]["issuerRef"]["name"]
  }
}
