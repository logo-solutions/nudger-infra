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

# ---------------------------------------------------------------------------
# Namespace ingress-nginx
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

# ---------------------------------------------------------------------------
# Ingress NGINX (via Helm) + Hardening hook
# ---------------------------------------------------------------------------
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  values = [
    yamlencode({
      controller = {
        publishService = { enabled = true }

        service = {
          type = "LoadBalancer"
        }

        ingressClassResource = {
          name            = "nginx"
          controllerValue = "k8s.io/ingress-nginx"
          enabled         = true
          default         = true
        }

        admissionWebhooks = {
          enabled = true
          patch = { enabled = true }
        }
      }
    }),

    file("${path.module}/ingress-nginx-hardening.yaml")
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "ingress_nginx_info" {
  value = {
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}
