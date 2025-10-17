output "vault_ingress_host" {
  description = "Nom de domaine du Vault"
  value       = var.vault_domain
}

output "vault_cert_secret" {
  description = "Secret TLS généré par cert-manager"
  value       = "vault-tls"
}
