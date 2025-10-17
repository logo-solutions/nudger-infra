terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

# ───────────────────────────────
# Providers
# ───────────────────────────────

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

# ───────────────────────────────
# Namespace Vault
# ───────────────────────────────

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

# ───────────────────────────────
# Déploiement Helm Vault
# ───────────────────────────────

resource "helm_release" "vault" {
  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.28.1"

  # Valeurs générées depuis le template
  values = [templatefile("${path.module}/values-vault.yaml.tmpl", {
    vault_domain   = var.vault_domain
    cluster_issuer = var.cluster_issuer
  })]

  depends_on = [
    kubernetes_namespace.vault
  ]
}

# ───────────────────────────────
# Outputs
# ───────────────────────────────

output "vault_url" {
  value       = "https://${var.vault_domain}"
  description = "URL publique du Vault"
}

output "vault_namespace" {
  value       = kubernetes_namespace.vault.metadata[0].name
  description = "Namespace Vault"
}

