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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
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
# Namespace cert-manager
# ───────────────────────────────

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# ───────────────────────────────
# Installation manuelle des CRDs
# ───────────────────────────────

resource "null_resource" "install_certmanager_crds" {
  provisioner "local-exec" {
    command = <<EOT
      echo "📦 Installation des CRDs cert-manager..."
      kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.crds.yaml
      echo "✅ CRDs installées."
    EOT
  }
}

# ───────────────────────────────
# Helm release cert-manager (sans CRDs)
# ───────────────────────────────

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.1"

  create_namespace = false

  values = [yamlencode({
    installCRDs = false
    prometheus  = { enabled = false }
    webhook     = { timeoutSeconds = 30 }
  })]

  depends_on = [
    null_resource.install_certmanager_crds
  ]
}

# ───────────────────────────────
# Secret Cloudflare API Token
# ───────────────────────────────

variable "cloudflare_api_token" {
  description = "Cloudflare API Token pour DNS-01"
  type        = string
  sensitive   = true
}
# ───────────────────────────────
# Déclencheur pour forcer la mise à jour du secret Cloudflare
# ───────────────────────────────
resource "null_resource" "cloudflare_secret_trigger" {
  triggers = {
    token = var.cloudflare_api_token
  }
}

resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    api-token = var.cloudflare_api_token 
  }

  type = "Opaque"
  lifecycle {
    replace_triggered_by = [null_resource.cloudflare_secret_trigger]
}
}

# ───────────────────────────────
# ClusterIssuer Let's Encrypt
# ───────────────────────────────

variable "email" {
  description = "Adresse e-mail utilisée pour Let's Encrypt"
  type        = string
}

variable "dns_zone" {
  description = "Zone DNS Cloudflare"
  type        = string
}

resource "null_resource" "wait_for_certmanager_crds" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Attente des CRDs cert-manager..."
      for i in $(seq 1 30); do
        if kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
          echo "✅ CRDs cert-manager prêtes."
          exit 0
        fi
        sleep 2
      done
      echo "❌ Timeout: CRDs cert-manager non détectées."
      exit 1
    EOT
  }
  depends_on = [helm_release.cert_manager]
}
resource "null_resource" "wait_for_certmanager_api" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Attente de l'enregistrement du CRD ClusterIssuer dans l'API Kubernetes..."
      for i in $(seq 1 60); do
        if kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
          echo "✅ CRD ClusterIssuer détecté."
          exit 0
        fi
        sleep 2
      done
      echo "❌ Timeout: le CRD ClusterIssuer n'est toujours pas présent après 2 minutes."
      exit 1
    EOT
  }

  depends_on = [helm_release.cert_manager]
}

# ───────────────────────────────
# Outputs
# ───────────────────────────────

output "cert_manager_status" {
  value = {
    namespace        = kubernetes_namespace.cert_manager.metadata[0].name
    cloudflare_secret = kubernetes_secret.cloudflare_api_token.metadata[0].name
    cluster_issuer   = "letsencrypt-dns"
  }
}
# ───────────────────────────────
# Vérification du secret Cloudflare
# ───────────────────────────────
resource "null_resource" "check_cloudflare_token" {
  provisioner "local-exec" {
    command = <<EOT
      echo "🔍 Vérification du secret Cloudflare dans Kubernetes..."
      token_in_k8s=$(kubectl get secret cloudflare-api-token-secret -n cert-manager -o jsonpath='{.data.api-token}' | base64 -d)
      token_in_bw="${var.cloudflare_api_token}"

      if [ "$token_in_k8s" = "$token_in_bw" ]; then
        echo "✅ Token Cloudflare identique entre Bitwarden et Kubernetes."
      else
        echo "❌ Token Cloudflare différent !"
        echo "  - K8s : $token_in_k8s"
        echo "  - BW  : $token_in_bw"
        exit 1
      fi
    EOT
  }

  depends_on = [kubernetes_secret.cloudflare_api_token]
}
