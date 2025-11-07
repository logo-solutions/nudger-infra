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

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

# Créer les certificats TLS pour chaque environnement
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

# Déployer Ingress Nginx avec Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  values = [yamlencode({
    controller = {
      publishService = { enabled = true }
      watchNamespace = ""
      allowSnippetAnnotations = true
      metrics = { enabled = false }

      service = {
        type = "NodePort"
        nodePorts = {
          http  = 30080
          https = 30443
        }
      }

      containerPort = {
        http  = 80
        https = 443
      }

      extraArgs = {
        "default-ssl-certificate" = "recette/tls-xwiki"
      }

      ingressClassResource = {
        name = "nginx"
        controllerValue = "k8s.io/ingress-nginx"
        enabled = true
        default = true
      }

      admissionWebhooks = {
        enabled = true
        patch = { enabled = true }
      }
    }
  })]

  depends_on = [kubernetes_namespace.ingress_nginx]
}

# Créer les Ingress pour les environnements recette et intégration
resource "kubernetes_manifest" "ingress_xwiki_recette" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = "recette"
      annotations = {
        "acme.cert-manager.io/http01-edit-in-place" = "true"
        "cert-manager.io/cluster-issuer" = "letsencrypt-dns"
        "kubernetes.io/ingress.class" = "nginx"
      }
    }
    spec = {
      rules = [
        {
          host = "xwiki.recette.nudger.logo-solutions.fr"
          http = {
            paths = [
              {
                backend = {
                  service = {
                    name = "xwiki"
                    port = { number = 80 }
                  }
                }
                path = "/"
                pathType = "Prefix"
              }
            ]
          }
        }
      ]
      tls = [
        {
          hosts = ["xwiki.recette.nudger.logo-solutions.fr"]
          secretName = "tls-xwiki"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_xwiki_integration" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "xwiki"
      namespace = "integration"
      annotations = {
        "acme.cert-manager.io/http01-edit-in-place" = "true"
        "cert-manager.io/cluster-issuer" = "letsencrypt-dns"
        "kubernetes.io/ingress.class" = "nginx"
      }
    }
    spec = {
      rules = [
        {
          host = "xwiki.integration.nudger.logo-solutions.fr"
          http = {
            paths = [
              {
                backend = {
                  service = {
                    name = "xwiki"
                    port = { number = 80 }
                  }
                }
                path = "/"
                pathType = "Prefix"
              }
            ]
          }
        }
      ]
      tls = [
        {
          hosts = ["xwiki.integration.nudger.logo-solutions.fr"]
          secretName = "tls-xwiki"
        }
      ]
    }
  }
}

# ✅ Patch du déploiement ingress-nginx-controller via kubectl (local-exec)
resource "null_resource" "patch_ingress_nginx_hostnetwork" {
  provisioner "local-exec" {
    command = <<EOT
kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}'
EOT
  }

  depends_on = [helm_release.ingress_nginx]
}

# Sorties
output "ingress_nginx_info" {
  value = {
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    nodeports = {
      http  = 30080
      https = 30443
    }
  }
}
