terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# ───────────────────────────────
# Variables
# ───────────────────────────────
variable "vault_namespace" {
  description = "Namespace où Vault est déployé"
  type        = string
  default     = "vault"
}

variable "host_path" {
  description = "Chemin local sur le noeud (ex: /var/lib/vault/data)"
  type        = string
  default     = "/var/lib/vault/data"
}

variable "storage_size" {
  description = "Taille du volume persistant Vault"
  type        = string
  default     = "5Gi"
}

variable "master_ip" {
  description = "Adresse IP du nœud master hébergeant Vault"
  type        = string
  default     = "91.98.16.184"
}

variable "ssh_private_key" {
  description = "Chemin vers la clé SSH permettant d’accéder au master"
  type        = string
  default     = "~/.ssh/hetzner-bastion"
}

variable "ssh_user" {
  description = "Utilisateur SSH pour le master"
  type        = string
  default     = "root"
}

# ───────────────────────────────
# Préparation du répertoire Vault sur le master
# ───────────────────────────────
resource "null_resource" "prepare_vault_dir" {
  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key))
  }

  provisioner "remote-exec" {
    inline = [
      "echo '📂 Préparation du répertoire Vault sur le master...'",
      "mkdir -p /var/lib/vault/data",
      "chown -R 100:1000 /var/lib/vault",
      "chmod -R 770 /var/lib/vault",
      "ls -ld /var/lib/vault /var/lib/vault/data"
    ]
  }
}

# ───────────────────────────────
# Namespace Vault
# ───────────────────────────────
resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.vault_namespace
  }
}

# ───────────────────────────────
# PersistentVolume (Vault)
# ───────────────────────────────
resource "kubernetes_persistent_volume" "vault_data" {
  metadata {
    name = "pv-vault-data"
    labels = {
      app  = "vault"
      type = "local"
    }
  }

  spec {
    capacity = {
      storage = var.storage_size
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_reclaim_policy = "Retain"

    storage_class_name = "manual"

  persistent_volume_source {
    host_path {
      path = var.host_path
    }
   }
   }
  

  depends_on = [null_resource.prepare_vault_dir]
}

# ───────────────────────────────
# PersistentVolumeClaim (Vault)
# ───────────────────────────────
resource "kubernetes_persistent_volume_claim" "vault_data_claim" {
  metadata {
    name      = "data-vault-0"
    namespace = var.vault_namespace
    labels = {
      app = "vault"
    }
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

  depends_on = [
    kubernetes_namespace.vault,
    kubernetes_persistent_volume.vault_data
  ]
}

# ───────────────────────────────
# Outputs
# ───────────────────────────────
output "pv_name" {
  value       = kubernetes_persistent_volume.vault_data.metadata[0].name
  description = "Nom du PersistentVolume Vault"
}

output "pvc_name" {
  value       = kubernetes_persistent_volume_claim.vault_data_claim.metadata[0].name
  description = "Nom du PersistentVolumeClaim Vault"
}

output "vault_namespace" {
  value       = var.vault_namespace
  description = "Namespace Vault"
}
