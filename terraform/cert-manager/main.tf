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
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.3"
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

provider "vault" {
  address = "https://vault.nudger.logo-solutions.fr"
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}
# ───────────────────────────────
# Namespace cert-manager
# ───────────────────────────────

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# ───────────────────────────────
# Helm release : cert-manager
# ───────────────────────────────

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.1"

  values = [yamlencode({
    installCRDs = true
    prometheus  = { enabled = false }
    webhook     = { timeoutSeconds = 30 }
  })]

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}

# ───────────────────────────────
# Secret Cloudflare API Token
# ───────────────────────────────
data "vault_kv_secret_v2" "cloudflare" {
  mount = "secret"
  name  = "cert-manager/cloudflare"
}
resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    api-token = base64encode(var.cloudflare_api_token)
  }

  type = "Opaque"
}

# ───────────────────────────────
# ClusterIssuer Let's Encrypt (DNS-01)
# ───────────────────────────────

resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  manifest = yamldecode(templatefile("${path.module}/templates/clusterissuer-letsencrypt-dns.yaml.tmpl", {
    email               = var.email
    cloudflare_api_token_secret = kubernetes_secret.cloudflare_api_token.metadata[0].name
    dns_zone            = var.dns_zone
    environment         = var.environment
  }))

  depends_on = [
    helm_release.cert_manager
  ]
}

# ───────────────────────────────
# Outputs
# ───────────────────────────────

output "clusterissuer_name" {
  value = "letsencrypt-dns"
  description = "Nom du ClusterIssuer Let’s Encrypt"
}

output "cert_manager_namespace" {
  value = kubernetes_namespace.cert_manager.metadata[0].name
}

output "cloudflare_secret_name" {
  value = kubernetes_secret.cloudflare_api_token.metadata[0].name
}
