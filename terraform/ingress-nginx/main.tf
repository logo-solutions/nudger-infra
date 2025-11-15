terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
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

# --------------------------------------------------------------------------
# Namespace ingress-nginx
# --------------------------------------------------------------------------
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

# --------------------------------------------------------------------------
# Certificat TLS recette
# --------------------------------------------------------------------------
resource "kubernetes_manifest" "tls_xwiki_recette" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "tls-xwiki"
      namespace = "recette"
    }
    spec = {
      secretName = "tls-xwiki"
      dnsNames   = ["xwiki.recette.nudger.logo-solutions.fr"]
      issuerRef = {
        name = "letsencrypt-dns"
        kind = "ClusterIssuer"
      }
      usages = ["digital signature", "key encipherment"]
    }
  }
}

# --------------------------------------------------------------------------
# Certificat TLS intégration
# --------------------------------------------------------------------------
resource "kubernetes_manifest" "tls_xwiki_integration" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "tls-xwiki"
      namespace = "integration"
    }
    spec = {
      secretName = "tls-xwiki"
      dnsNames   = ["xwiki.integration.nudger.logo-solutions.fr"]
      issuerRef = {
        name = "letsencrypt-dns"
        kind = "ClusterIssuer"
      }
      usages = ["digital signature", "key encipherment"]
    }
  }
}

# --------------------------------------------------------------------------
# Ingress-NGINX via Helm
# --------------------------------------------------------------------------
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  values = [
    yamlencode({
      controller = {
        publishService          = { enabled = true }
        watchNamespace          = ""
        allowSnippetAnnotations = true
        metrics                 = { enabled = false }

        # MetalLB compatible
        service = {
          type = "LoadBalancer"
        }

        containerPort = {
          http  = 80
          https = 443
        }

        ingressClassResource = {
          name            = "nginx"
          controllerValue = "k8s.io/ingress-nginx"
          enabled         = true
          default         = true
        }

        admissionWebhooks = {
          enabled = true
          patch   = { enabled = true }
        }
      }
    }),

    file("${path.module}/ingress-nginx-hardening.yaml")
  ]

  depends_on = [
    kubernetes_namespace.ingress_nginx
  ]
}

# --------------------------------------------------------------------------
# Ingress XWiki RECETTE
# --------------------------------------------------------------------------
resource "kubernetes_manifest" "ingress_xwiki_recette" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = "recette"
      annotations = {
        "acme.cert-manager.io/http01-edit-in-place" = "true"
        "cert-manager.io/cluster-issuer"             = "letsencrypt-dns"
        "kubernetes.io/ingress.class"                = "nginx"
      }
    }
    spec = {
      rules = [
        {
          host = "xwiki.recette.nudger.logo-solutions.fr"
          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "xwiki"
                    port = { number = 80 }
                  }
                }
              }
            ]
          }
        }
      ]
      tls = [
        {
          hosts      = ["xwiki.recette.nudger.logo-solutions.fr"]
          secretName = "tls-xwiki"
        }
      ]
    }
  }
}

# --------------------------------------------------------------------------
# Ingress XWiki INTEGRATION
# --------------------------------------------------------------------------
resource "kubernetes_manifest" "ingress_xwiki_integration" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = "integration"
      annotations = {
        "acme.cert-manager.io/http01-edit-in-place" = "true"
        "cert-manager.io/cluster-issuer"             = "letsencrypt-dns"
        "kubernetes.io/ingress.class"                = "nginx"
      }
    }
    spec = {
      rules = [
        {
          host = "xwiki.integration.nudger.logo-solutions.fr"
          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "xwiki"
                    port = { number = 80 }
                  }
                }
              }
            ]
          }
        }
      ]
      tls = [
        {
          hosts      = ["xwiki.integration.nudger.logo-solutions.fr"]
          secretName = "tls-xwiki"
        }
      ]
    }
  }
}

# --------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------
output "ingress_nginx_info" {
  value = {
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}
