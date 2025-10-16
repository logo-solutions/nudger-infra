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

# ───────────────────────────────
# Namespace Longhorn
# ───────────────────────────────
resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"
  }
}

# ───────────────────────────────
# Helm Release : Longhorn
# ───────────────────────────────
resource "helm_release" "longhorn" {
  name       = "longhorn"
  namespace  = kubernetes_namespace.longhorn.metadata[0].name
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.7.1" # version stable octobre 2025

  values = [yamlencode({
    defaultSettings = {
      backupTarget              = "nfs://"
      defaultDataPath            = "/var/lib/longhorn"
      createDefaultDiskLabeledNodes = true
    }
    persistence = {
      defaultClass = true
      reclaimPolicy = "Delete"
    }
    ingress = {
      enabled           = false
    }
  })]

  depends_on = [
    kubernetes_namespace.longhorn
  ]
}

# ───────────────────────────────
# StorageClass par défaut
# ───────────────────────────────
resource "null_resource" "set_default_storageclass" {
  depends_on = [helm_release.longhorn]

  provisioner "local-exec" {
    command = <<EOT
      kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOT
  }
}

