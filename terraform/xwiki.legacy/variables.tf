variable "cloudflare_api_token" {
  type        = string
  description = "API Token Cloudflare pour DNS-01"
}

variable "cloudflare_email" {
  type        = string
  description = "Adresse email associée à Cloudflare"
}

variable "xwiki_domain" {
  type        = string
  description = "Nom de domaine utilisé pour accéder à XWiki"
}
