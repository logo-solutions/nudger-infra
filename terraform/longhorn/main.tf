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

# ─────────────────────────────────────────────
# STORAGECLASS : Longhorn - 1 Replica (single-node)
# ─────────────────────────────────────────────
resource "kubernetes_storage_class" "longhorn_single_node" {
  metadata {
    name = "longhorn"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "driver.longhorn.io"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"
  allow_volume_expansion = true

  parameters = {
    numberOfReplicas     = "1"
    staleReplicaTimeout  = "20"
    dataLocality         = "best-effort"
    fromBackup           = ""
  }
}
