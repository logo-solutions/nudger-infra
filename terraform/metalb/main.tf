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
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

locals {
  namespace       = "metallb-system"
  metallb_chart   = "metallb"
  metallb_repo    = "https://metallb.github.io/metallb"
  metallb_version = "0.14.8"

  hetzner_ip      = "91.98.16.184"
}

# -----------------------------------------------------------------------------
# Namespace MetalLB
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "metallb" {
  metadata {
    name = local.namespace
  }
}

# -----------------------------------------------------------------------------
# Helm: MetalLB + Hardening
# -----------------------------------------------------------------------------
resource "helm_release" "metallb" {
  name       = local.metallb_chart
  repository = local.metallb_repo
  chart      = local.metallb_chart
  namespace  = kubernetes_namespace.metallb.metadata[0].name
  version    = local.metallb_version

  cleanup_on_fail = true
  create_namespace = false

  values = [
    yamlencode({
      controller = {
        # SECURITÉ DU CONTROLLER
        securityContext = {
          runAsNonRoot            = true
          runAsUser               = 65534
          allowPrivilegeEscalation = false
          readOnlyRootFilesystem   = true
          capabilities = {
            drop = ["ALL"]
          }
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "300m"
            memory = "256Mi"
          }
        }
      }

      speaker = {
        # HETZNER : L2 sur interface publique
        l2 = {
          interfaces = ["eth0"]
        }

        # Le speaker a besoin de NET_ADMIN / NET_RAW → on serre le reste
        securityContext = {
          runAsNonRoot            = false
          allowPrivilegeEscalation = false
          readOnlyRootFilesystem   = true
          capabilities = {
            drop = ["ALL"]
            add  = ["NET_ADMIN", "NET_RAW"]
          }
        }
	frr = {
	  enabled = false
	}
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "300m"
            memory = "256Mi"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.metallb]
}

# -----------------------------------------------------------------------------
# IPAddressPool : pool unique = IP publique Hetzner
# -----------------------------------------------------------------------------
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
      addresses = ["${local.hetzner_ip}-${local.hetzner_ip}"]
      autoAssign = true
    }
  }
}

# -----------------------------------------------------------------------------
# L2Advertisement
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "l2advertisement" {
  depends_on = [
    helm_release.metallb,
    kubernetes_manifest.ipaddresspool
  ]

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

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "metallb_namespace" {
  value = kubernetes_namespace.metallb.metadata[0].name
}

output "metallb_pool" {
  value = {
    name      = kubernetes_manifest.ipaddresspool.manifest.metadata.name
    addresses = kubernetes_manifest.ipaddresspool.manifest.spec.addresses
  }
}

output "metallb_status" {
  value = "MetalLB installed, L2 mode on eth0, pool ${local.hetzner_ip} actif"
}
