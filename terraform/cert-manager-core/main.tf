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

# -----------------------------------------------------------------------------
# Namespace cert-manager
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# -----------------------------------------------------------------------------
# Helm Release cert-manager — version durcie, stable, sans fichier externe
# -----------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.1"

  create_namespace = false

  values = [
    yamlencode({
      installCRDs = true
      prometheus  = { enabled = false }

      # ---------------------------------------------------------
      # HARDENING GLOBAL
      # ---------------------------------------------------------
      podSecurityContext = {
        seccompProfile = {
          type = "RuntimeDefault"
        }
      }

      containerSecurityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        capabilities = { drop = ["ALL"] }
      }
      # ---------------------------------------------------------
      # HARDENING GLOBAL — RUN AS GROUP FIX
      # ---------------------------------------------------------
      podSecurityContext = {
        runAsUser  = 65534
        runAsGroup = 1000
        fsGroup    = 1000
        seccompProfile = {
          type = "RuntimeDefault"
        }
      }

      containerSecurityContext = {
        runAsNonRoot             = true
        runAsUser                = 65534
        runAsGroup               = 1000
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        capabilities = {
          drop = ["ALL"]
        }
      }
      automountServiceAccountToken = true

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }

      # ---------------------------------------------------------
      # CAINJECTOR
      # ---------------------------------------------------------
      cainjector = {
        podSecurityContext = {
          runAsUser  = 65534
          runAsGroup = 1000
          fsGroup    = 1000
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        containerSecurityContext = {
          runAsNonRoot             = true
          runAsUser                = 65534
          runAsGroup               = 1000
          allowPrivilegeEscalation = false
          readOnlyRootFilesystem   = true
          capabilities = {
            drop = ["ALL"]
          }
        }
        automountServiceAccountToken = true
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "256Mi"
          }
        }
      }

      # ---------------------------------------------------------
      # WEBHOOK
      # ---------------------------------------------------------
      webhook = {
        podSecurityContext = {
          runAsUser  = 65534
          runAsGroup = 1000
          fsGroup    = 1000
          seccompProfile = {
            type = "RuntimeDefault"
          }
        }
        containerSecurityContext = {
          runAsNonRoot             = true
          runAsUser                = 65534
          runAsGroup               = 1000
          allowPrivilegeEscalation = false
          readOnlyRootFilesystem   = true
          capabilities = {
            drop = ["ALL"]
          }
        }
        automountServiceAccountToken = true
        timeoutSeconds = 30
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}

# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------
output "cert_manager_namespace" {
  value = kubernetes_namespace.cert_manager.metadata[0].name
}
