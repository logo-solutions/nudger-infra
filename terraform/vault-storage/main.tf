terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}
data "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_namespace" "vault" {
  count = length(data.kubernetes_namespace.vault.metadata) == 0 ? 1 : 0

  metadata {
    name = "vault"
  }
}

# ───────────────────────────────
# PersistentVolume (PV)
# ───────────────────────────────
resource "kubernetes_persistent_volume" "vault_data" {
  metadata {
    name = "pv-vault-data"
    labels = {
      type = "local"
    }
  }

  spec {
    capacity = {
      storage = var.storage_size
    }
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = "manual"
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = var.host_path
      }
    }
  }
}

# ───────────────────────────────
# PersistentVolumeClaim (PVC)
# ───────────────────────────────
resource "kubernetes_persistent_volume_claim" "vault_data_claim" {
  metadata {
    name      = "data-vault-0"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  spec {
    access_modes      = ["ReadWriteOnce"]
    storage_class_name = "manual"

    resources {
      requests = {
        storage = var.storage_size
      }
    }

    volume_name = kubernetes_persistent_volume.vault_data.metadata[0].name
  }

  depends_on = [kubernetes_persistent_volume.vault_data]
}
