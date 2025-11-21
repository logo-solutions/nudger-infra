terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
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

resource "kubernetes_namespace" "kubescape" {
  metadata { name = "kubescape" }
}

resource "helm_release" "kubescape_operator" {
  name       = "kubescape"
  repository = "https://kubescape.github.io/helm-charts/"
  chart      = "kubescape-operator"
  version    = "1.29.10"

  namespace        = kubernetes_namespace.kubescape.metadata[0].name
  create_namespace = false

  # ⚙️ Définis explicitement ton cluster name
  set {
    name  = "clusterName"
    value = "nudger-cluster"
  }

  set {
    name  = "capabilities.continuousScan"
    value = "enable"
  }

  set {
    name  = "capabilities.vulnerabilityScan"
    value = "enable"
  }

  set {
    name  = "capabilities.relevancy"
    value = "enable"
  }

  set {
    name  = "capabilities.runtimeObservability"
    value = "enable"
  }
  set {
    name  = "nodeAgent.enabled"
    value = "false"
  }
  set {
    name  = "capabilities.prometheusExporter"
    value = "enable"
  }
}
