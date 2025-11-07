terraform {
  required_version = ">= 1.9.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

locals {
  namespace       = "metallb-system"
  metallb_chart   = "metallb"
  metallb_repo    = "https://metallb.github.io/metallb"
  metallb_version = "0.14.8"
}

# Namespace
resource "kubernetes_namespace" "metallb" {
  metadata {
    name = local.namespace
  }
}

# Déploiement du chart MetalLB (installe aussi les CRDs)
resource "helm_release" "metallb" {
  name       = local.metallb_chart
  repository = local.metallb_repo
  chart      = local.metallb_chart
  namespace  = kubernetes_namespace.metallb.metadata[0].name
  version    = local.metallb_version
  create_namespace = false
  cleanup_on_fail  = true
}

# Pools IP et L2Advertisement (créés après que Helm ait fini)
resource "kubernetes_manifest" "ipaddresspool" {
  depends_on = [helm_release.metallb]
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "default-pool"
      namespace = local.namespace
    }
    spec = {
      addresses = ["91.98.16.184-91.98.16.184"]
    }
  }
}

resource "kubernetes_manifest" "l2advertisement" {
  depends_on = [helm_release.metallb]
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "default-advertisement"
      namespace = local.namespace
    }
    spec = {}
  }
}
