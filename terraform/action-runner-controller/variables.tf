variable "arc_namespace" {
  description = "Namespace pour ARC"
  type        = string
  default     = "arc"
}

variable "arc_version" {
  description = "Version du chart ARC (controller et runner)"
  type        = string
  # Ex: "0.9.3" — adapte à ta version actuelle
  default     = "0.9.3"
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "Contenu PEM de la clé privée GitHub App"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "URL GitHub cible (ex: https://github.com/logo-solutions/nudger-infra)"
  type        = string
}

variable "runner_set_name" {
  description = "Nom du Runner Scale Set"
  type        = string
  default     = "nudger-autoscaling-set"
}

variable "min_runners" {
  description = "Nombre minimal de runners"
  type        = number
  default     = 1
}
variable "runner_scale_set_name" {
  description = "Nom du Runner Scale Set (transmis au module ARC)"
  type        = string
  default     = "nudger-autoscaling-set"
}
variable "max_runners" {
  description = "Nombre maximal de runners"
  type        = number
  default     = 2
}
