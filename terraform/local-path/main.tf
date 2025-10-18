terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  backend "local" {
    path = "/root/.terraform/local-path/terraform.tfstate"
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

# Namespace local-path
resource "kubernetes_namespace" "local_path" {
  metadata {
    name = "local-path-storage"
  }
}

# Helm chart depuis repo public Containeroo
resource "helm_release" "local_path_provisioner" {
  name             = "local-path-provisioner"
  namespace        = kubernetes_namespace.local_path.metadata[0].name
  repository       = "https://charts.containeroo.ch"
  chart            = "local-path-provisioner"
  version          = "0.0.22"
  create_namespace = false
  values           = [file("${path.module}/values.yaml")]
}

# Validation post-déploiement
resource "null_resource" "wait_for_sc" {
  depends_on = [helm_release.local_path_provisioner]

  provisioner "local-exec" {
    command = <<-EOT
      echo "⏳ Vérification du StorageClass local-path..."
      for i in $(seq 1 20); do
        if kubectl get sc local-path >/dev/null 2>&1; then
          echo "✅ StorageClass local-path détecté."
          exit 0
        fi
        sleep 2
      done
      echo "❌ Échec : StorageClass local-path introuvable après 40s."
      exit 1
    EOT
  }
}
