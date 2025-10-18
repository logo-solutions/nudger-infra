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

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

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
        "default-ssl-certificate" = "xwiki/tls-xwiki"
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

output "ingress_nginx_info" {
  value = {
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    nodeports = {
      http  = 30080
      https = 30443
    }
  }
}
