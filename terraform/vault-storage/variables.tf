variable "host_path" {
  description = "Chemin local sur le master où seront stockées les données Vault"
  type        = string
  default     = "/var/lib/vault/data"
}

variable "storage_size" {
  description = "Taille du volume de stockage"
  type        = string
  default     = "5Gi"
}
