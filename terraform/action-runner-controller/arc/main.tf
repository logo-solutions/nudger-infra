terraform {
  required_version = ">= 1.7.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

###########################
# Variables
###########################

variable "arc_namespace" {
  description = "Namespace pour ARC"
  type        = string
  default     = "arc"
}

variable "arc_version" {
  description = "Version du chart ARC (controller et runner)"
  type        = string
  default     = "0.13.0"
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
  default     = "https://github.com/logo-solutions/nudger-infra"
}

variable "runner_scale_set_name" {
  description = "Nom du Runner Scale Set"
  type        = string
  default     = "nudger-autoscaling-set"
}

variable "min_runners" {
  description = "Nombre minimal de runners"
  type        = number
  default     = 1
}

variable "max_runners" {
  description = "Nombre maximal de runners"
  type        = number
  default     = 2
}

###########################
# Namespace ARC
###########################

resource "kubernetes_namespace" "arc" {
  metadata {
    name = var.arc_namespace
  }
}

###########################
# Secret GitHub App
###########################

# 👉 Utilisation de base64encode pour éviter l'erreur "string_data non supporté"
resource "kubernetes_secret" "github_app" {
  metadata {
    name      = "github-app-secret"
    namespace = kubernetes_namespace.arc.metadata[0].name
  }

  type = "Opaque"

  data = {
    github_app_id              = base64encode(var.github_app_id)
    github_app_installation_id = base64encode(var.github_app_installation_id)
    github_app_private_key     = base64encode(var.github_app_private_key)
  }

  lifecycle {
  replace_triggered_by = [
    null_resource.github_secret_trigger  
 ]
}
}

# 👇 Déclencheur artificiel basé sur les variables
resource "null_resource" "github_secret_trigger" {
  triggers = {
    hash = sha256(join(",", [
      var.github_app_id,
      var.github_app_installation_id,
      var.github_app_private_key
    ]))
  }
}
###########################
# Helm chart : ARC Controller
###########################

resource "helm_release" "arc_controller" {
  name             = "arc"
  namespace        = kubernetes_namespace.arc.metadata[0].name
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = var.arc_version
  create_namespace = false
  wait             = true

  depends_on = [kubernetes_namespace.arc]
}

###########################
# Helm chart : Runner Scale Set
###########################

resource "helm_release" "runner_scale_set" {
  name             = "nudger-runner"
  namespace        = kubernetes_namespace.arc.metadata[0].name
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = var.arc_version
  create_namespace = false
  wait             = true

  set {
    name  = "githubConfigUrl"
    value = var.github_repo_url
  }

  set {
    name  = "githubConfigSecret"
    value = kubernetes_secret.github_app.metadata[0].name
  }

  set {
    name  = "runnerScaleSetName"
    value = var.runner_scale_set_name
  }

  set {
    name  = "minRunners"
    value = tostring(var.min_runners)
  }

  set {
    name  = "maxRunners"
    value = tostring(var.max_runners)
  }

  set {
    name  = "controllerServiceAccount.name"
    value = "arc-gha-rs-controller"
  }

  depends_on = [
    helm_release.arc_controller,
    kubernetes_secret.github_app
  ]
}

###########################
# Outputs
###########################

output "arc_namespace" {
  description = "Nom du namespace ARC"
  value       = kubernetes_namespace.arc.metadata[0].name
}

output "arc_secret" {
  description = "Nom du secret GitHub App"
  value       = kubernetes_secret.github_app.metadata[0].name
}

output "runner_scale_set_name" {
  description = "Nom du Runner Scale Set"
  value       = var.runner_scale_set_name
}
