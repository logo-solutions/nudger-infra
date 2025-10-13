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

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

# ─────────────────────────────────────────────
# XWIKI — Déploiement local (Helm chart embarqué)
# ─────────────────────────────────────────────

# Namespace explicite
resource "kubernetes_namespace" "xwiki" {
  metadata {
    name = "xwiki"
  }
}

# Déploiement XWiki
resource "helm_release" "xwiki" {
  name       = "xwiki"
  namespace  = kubernetes_namespace.xwiki.metadata[0].name
  chart      = "${path.module}/xwiki-helm/xwiki"
  values     = [file("${path.module}/xwiki-helm/xwiki/values.yaml")]

  create_namespace = false

  # Optionnel : tag explicite pour suivi
  set {
    name  = "image.tag"
    value = "lts-mysql-tomcat"
  }

  # Exemple : forcer ingress ou storageClass sans toucher au YAML
  set {
    name  = "ingress.enabled"
    value = "false"
  }
  set {
    name  = "persistence.storageClass"
    value = "longhorn"
  }

  depends_on = [
    kubernetes_namespace.xwiki
  ]
}

# ─────────────────────────────────────────────
# Sorties Terraform (infos utiles après apply)
# ─────────────────────────────────────────────
output "xwiki_namespace" {
  description = "Namespace de déploiement"
  value       = helm_release.xwiki.namespace
}

output "xwiki_service" {
  description = "Service interne XWiki"
  value = "kubectl get svc -n xwiki -o wide"

}
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# ─────────────────────────────────────────────────────────────
# CERT-MANAGER : Chart officiel Jetstack
# ─────────────────────────────────────────────────────────────

resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.14.5"
  create_namespace = false

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# ─────────────────────────────────────────────────────────────
# SECRET CLOUDFLARE pour DNS-01
# ─────────────────────────────────────────────────────────────

resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
    "api-token" = base64encode(var.cloudflare_api_token)
  }

  type = "Opaque"
}

# ─────────────────────────────────────────────────────────────
# ClusterIssuer DNS-01
# ─────────────────────────────────────────────────────────────

resource "kubernetes_manifest" "cluster_issuer" {
  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret.cloudflare_api_token
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns"
    }
    spec = {
      acme = {
        email  = var.cloudflare_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-dns"
        }
        solvers = [ {
          dns01 = {
            cloudflare = {
              email = var.cloudflare_email
              apiTokenSecretRef = {
                name = "cloudflare-api-token-secret"
                key  = "api-token"
              }
            }
          }
        } ]
      }
    }
  }
}
# ─────────────────────────────────────────────────────────────
# Ingress XWiki + certificat Let's Encrypt via cert-manager
# ─────────────────────────────────────────────────────────────

# 1️⃣ — Ingress XWiki
resource "kubernetes_manifest" "xwiki_ingress" {
  depends_on = [
    helm_release.xwiki,
    kubernetes_manifest.cluster_issuer  # ton ClusterIssuer "letsencrypt-dns"
  ]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = "xwiki"
      annotations = {
        "kubernetes.io/ingress.class"                = "nginx"
        "cert-manager.io/cluster-issuer"             = "letsencrypt-dns"
        "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
        "nginx.ingress.kubernetes.io/proxy-body-size" = "64m"
      }
    }
    spec = {
      ingressClassName = "nginx"
      tls = [
        {
          hosts      = ["xwiki.nudger.logo-solutions.fr"]
          secretName = "xwiki-tls"
        }
      ]
      rules = [
        {
          host = "xwiki.nudger.logo-solutions.fr"
          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                backend  = {
                  service = {
                    name = "xwiki"
                    port = {
                      number = 80
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
}

