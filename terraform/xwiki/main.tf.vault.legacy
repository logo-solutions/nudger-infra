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

  backend "local" {
    path = "/root/.terraform/xwiki/terraform.tfstate"
  }
}
# ─────────────────────────────────────────────
# PROVIDERS
# ─────────────────────────────────────────────

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

# ─────────────────────────────────────────────
# VAULT — Authentification via AppRole Terraform
# ─────────────────────────────────────────────

locals {
  vault_approle_path = "/root/.ansible/artifacts/master1/vault-terraform-approle.json"
}

data "local_file" "vault_approle" {
  filename = local.vault_approle_path
}

locals {
  vault_approle_creds = jsondecode(data.local_file.vault_approle.content)
}

provider "vault" {
  address          = "http://127.0.0.1:8200"

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = local.vault_approle_creds.role_id
      secret_id = local.vault_approle_creds.secret_id
    }
  }
}
# ─────────────────────────────────────────────
# SECRETS : import depuis Vault
# ─────────────────────────────────────────────

data "vault_generic_secret" "cloudflare" {
  path = "secret/cert-manager/cloudflare"
}

data "vault_generic_secret" "xwiki_db" {
  path = "secret/xwiki/database"
}

# ─────────────────────────────────────────────
# XWIKI — Déploiement local (Helm chart embarqué)
# ─────────────────────────────────────────────

resource "kubernetes_namespace" "xwiki" {
  metadata {
    name = "xwiki"
  }
}

resource "helm_release" "xwiki" {
  name       = "xwiki"
  namespace  = kubernetes_namespace.xwiki.metadata[0].name
  chart      = "${path.module}/xwiki-helm/xwiki"
  values     = [file("${path.module}/xwiki-helm/xwiki/values.yaml")]
  create_namespace = false

  set {
    name  = "image.tag"
    value = "lts-mysql-tomcat"
  }

  set {
    name  = "mysql.username"
    value = data.vault_generic_secret.xwiki_db.data["username"]
  }

  set {
    name  = "mysql.password"
    value = data.vault_generic_secret.xwiki_db.data["password"]
  }

  set {
    name  = "mysql.database"
    value = data.vault_generic_secret.xwiki_db.data["dbname"]
  }

  depends_on = [kubernetes_namespace.xwiki]
}

# ─────────────────────────────────────────────
# CERT-MANAGER — Jetstack chart officiel
# ─────────────────────────────────────────────

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

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

# ─────────────────────────────────────────────
# SECRET CLOUDFLARE — alimenté depuis Vault
# ─────────────────────────────────────────────

resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
  }

  data = {
    "api-token" = base64encode(data.vault_generic_secret.cloudflare.data["api_token"])
  }

  type = "Opaque"
}

# ─────────────────────────────────────────────
# CLUSTERISSUER DNS-01
# ─────────────────────────────────────────────

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
        email  = "loic@loic-solutions.fr"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-dns"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                email = "loic@loic-solutions.fr"
                apiTokenSecretRef = {
                  name = "cloudflare-api-token-secret"
                  key  = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }
}

# ─────────────────────────────────────────────
# INGRESS XWIKI + CERTIFICAT TLS
# ─────────────────────────────────────────────

resource "kubernetes_manifest" "xwiki_ingress" {
  depends_on = [
    helm_release.xwiki,
    kubernetes_manifest.cluster_issuer
  ]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = kubernetes_namespace.xwiki.metadata[0].name
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
        "cert-manager.io/cluster-issuer" = "letsencrypt-dns"
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
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

# ─────────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────────

output "xwiki_namespace" {
  description = "Namespace de déploiement"
  value       = helm_release.xwiki.namespace
}

output "xwiki_service" {
  description = "Service interne XWiki"
  value       = "kubectl get svc -n xwiki -o wide"
}
