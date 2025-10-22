#########################################################
# TERRAFORM - GITHUB ACTIONS RUNNER CONTROLLER (ARC)
# Déploiement industriel via Helm + Kubernetes providers
# Auteur : Loïc Bourmelon
#########################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9" # version stable avec bloc kubernetes
    }
  }
}

#########################################################
# PROVIDERS
#########################################################

# Provider Kubernetes - connexion au cluster
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# Provider Helm - utilise le provider Kubernetes ci-dessus
provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

#########################################################
# 1️⃣ Namespace dédié à ARC
#########################################################

resource "kubernetes_namespace" "arc" {
  metadata {
    name = "arc"
    labels = {
      "app.kubernetes.io/name" = "actions-runner-controller"
    }
  }
}

#########################################################
# 2️⃣ Installation du chart Helm ARC
#########################################################

# Le chart officiel est hébergé sur GitHub Container Registry
resource "helm_release" "arc_controller" {
  name       = "actions-runner-controller"
  namespace  = kubernetes_namespace.arc.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = "0.11.0"

  # Valeurs Helm optionnelles : ajustables selon tes besoins
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
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "8080"
        "prometheus.io/path"   = "/metrics"
      }
    })
  ]
}

#########################################################
# 3️⃣ Secret GitHub Token
#########################################################

# Ce token doit être un PAT GitHub avec permissions :
# repo, admin:repo_hook, workflow
variable "github_token" {
  description = "Token GitHub pour l'authentification du runner"
  type        = string
  sensitive   = true
}

resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "controller-manager"
    namespace = kubernetes_namespace.arc.metadata[0].name
  }
  data = {
    github_token = base64encode(var.github_token)
  }
}

#########################################################
# 4️⃣ Déploiement d’un RunnerDeployment
#########################################################

# Un RunnerDeployment déclare un pool de runners auto-gérés
resource "kubernetes_manifest" "runner_deployment" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "nudger-runner"
      namespace = kubernetes_namespace.arc.metadata[0].name
    }
    spec = {
      replicas = 1
      template = {
        spec = {
          repository = "logo-solutions/nudger-infra"
          labels     = ["self-hosted", "linux", "x64", "nudger"]
        }
      }
    }
  }

  depends_on = [helm_release.arc_controller]
}

#########################################################
# 5️⃣ Déploiement d’un HorizontalRunnerAutoscaler (optionnel)
#########################################################

# Permet d'ajuster le nombre de runners automatiquement
resource "kubernetes_manifest" "runner_autoscaler" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "nudger-autoscaler"
      namespace = kubernetes_namespace.arc.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = kubernetes_manifest.runner_deployment.manifest["metadata"]["name"]
      }
      minReplicas = 1
      maxReplicas = 3
      metrics = [
        {
          type = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
          repositoryNames = ["logo-solutions/nudger-infra"]
          scaleUpThreshold = 2
          scaleDownThreshold = 1
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.runner_deployment]
}

#########################################################
# FIN DU FICHIER
#########################################################
