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

# Namespace
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Helm install + CRDs
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.1"

  create_namespace = false

  values = [yamlencode({
    installCRDs = true
    prometheus  = { enabled = false }
    webhook     = { timeoutSeconds = 30 }
  })]
}
