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

# Namespace MetalLB
resource "kubernetes_namespace" "metallb" {
  metadata {
    name = local.namespace
  }
}

# Installation du chart MetalLB
resource "helm_release" "metallb" {
  name       = local.metallb_chart
  repository = local.metallb_repo
  chart      = local.metallb_chart
  namespace  = kubernetes_namespace.metallb.metadata[0].name
  version    = local.metallb_version
  cleanup_on_fail = true

  values = [
    yamlencode({
      controller = {
        securityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
          }
          runAsNonRoot = true
          runAsUser = 65534
        }
      }

      speaker = {
        # 🔥 OBLIGATOIRE POUR HETZNER CLOUD
        l2 = {
          interfaces = ["eth0"]
        }

        securityContext = {
          allowPrivilegeEscalation = false
          capabilities = {
            drop = ["ALL"]
            add  = ["NET_ADMIN", "NET_RAW"]
          }
          runAsNonRoot = false
        }
      }
    })
  ]
}

# Pool unique — ton IP Hetzner publique
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
      autoAssign = true
    }
  }
}

# Advertisement L2
resource "kubernetes_manifest" "l2advertisement" {
  depends_on = [helm_release.metallb]

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "default-advertisement"
      namespace = local.namespace
    }
    spec = {
      ipAddressPools = ["default-pool"]
    }
  }
}

output "metallb_status" {
  value = "MetalLB installed and IP pool 91.98.16.184 active"
}
