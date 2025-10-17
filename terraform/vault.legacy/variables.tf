variable "vault_domain" {
  description = "Nom de domaine public pour Vault"
  type        = string
  default     = "vault.nudger.logo-solutions.fr"
}

variable "email_acme" {
  description = "Adresse email pour Let's Encrypt"
  type        = string
  default     = "loic@loic-solutions.fr"
}

variable "cluster_issuer" {
  description = "Nom du ClusterIssuer cert-manager"
  type        = string
  default     = "letsencrypt-dns"
}
