variable "chart_version" {
  description = "Version du chart Helm local-path-provisioner"
  type        = string
  default     = "0.0.28"
}

variable "default_reclaim_policy" {
  description = "Politique de suppression du StorageClass"
  type        = string
  default     = "Delete"
}
