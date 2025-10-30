terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
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

# Namespace ARC
resource "kubernetes_namespace" "arc" {
  metadata {
    name = "arc"
    labels = {
      "app.kubernetes.io/name" = "actions-runner-controller"
    }
  }
}

# Chart Helm : actions-runner-controller
resource "helm_release" "arc_controller" {
  name       = "actions-runner-controller"
  namespace  = kubernetes_namespace.arc.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = "0.11.0"

  values = [
    yamlencode({
      replicaCount = 1
      serviceAccount = {
        create = true
        name   = "arc-controller-sa"
      }
      metrics = {
        controllerManagerAddr = ":8080"
        listenerAddr          = ":8080"
        listenerEndpoint      = "/metrics"
      }
    })
  ]
}
