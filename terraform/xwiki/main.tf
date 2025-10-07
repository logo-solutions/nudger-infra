terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.14.5"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

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

resource "kubernetes_manifest" "cluster_issuer" {
  depends_on = [helm_release.cert_manager]
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
        solvers = [{
          dns01 = {
            cloudflare = {
              email = var.cloudflare_email
              apiTokenSecretRef = {
                name = "cloudflare-api-token-secret"
                key  = "api-token"
              }
            }
          }
        }]
      }
    }
  }
}

resource "helm_release" "xwiki" {
  name             = "xwiki"
  namespace        = "xwiki"
  chart            = "${path.module}/charts/xwiki-1.6.3.tgz"
  create_namespace = true
  # Ingress / TLS
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hosts[0].host"
    value = var.xwiki_domain
  }
  # Assurer qu’il y a un chemin défini
  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }
  set {
    name  = "ingress.hosts[0].pathTypes[0]"
    value = "Prefix"
  }
  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-dns"
  }
  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.xwiki_domain
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "xwiki-tls"
  }

  # Override MySQL embarqué (à ajuster si nécessaire)
  set {
    name  = "mysql.enabled"
    value = "true"
  }
  set {
    name  = "mysql.auth.rootPassword"
    value = "RootPwd123"
  }
  set {
    name  = "mysql.auth.password"
    value = "XwikiUserPwd"
  }
  set {
    name  = "mysql.auth.database"
    value = "xwiki"
  }
  set {
    name  = "mysql.image.repository"
    value = "docker.io/bitnamilegacy/mysql"
  }
  set {
    name  = "mysql.image.tag"
    value = "8.0.34-debian-11-r0"
  }

  # Si le chart requiert une option "allowInsecureImages"
  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }
}
