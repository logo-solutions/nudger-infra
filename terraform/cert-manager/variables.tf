variable "email" {
  description = "Adresse e-mail utilisée pour Let's Encrypt"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Token API Cloudflare (avec droits DNS edit)"
  type        = string
  sensitive   = true
}

variable "dns_zone" {
  description = "Zone DNS Cloudflare principale (ex: logo-solutions.fr)"
  type        = string
}

variable "environment" {
  description = "Environnement (staging ou production)"
  type        = string
  default     = "production"
}
variable "vault_role_id" {
  description = "AppRole ID Terraform pour lire les secrets Vault"
  type        = string
}

variable "vault_secret_id" {
  description = "AppRole Secret ID Terraform"
  type        = string
  sensitive   = true
}
