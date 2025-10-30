terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

variable "github_token" {
  description = "Token GitHub pour l'authentification du runner"
  type        = string
  sensitive   = true
}

# Secret pour GitHub Token
resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "controller-manager"
    namespace = "arc"
  }
  data = {
    github_token = base64encode(var.github_token)
  }
}

# RunnerDeployment
resource "kubernetes_manifest" "runner_deployment" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "nudger-runner"
      namespace = "arc"
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

  depends_on = [kubernetes_secret.github_token]
}

# Autoscaler
resource "kubernetes_manifest" "runner_autoscaler" {
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "nudger-autoscaler"
      namespace = "arc"
    }
    spec = {
      scaleTargetRef = {
        name = kubernetes_manifest.runner_deployment.manifest["metadata"]["name"]
      }
      minReplicas = 1
      maxReplicas = 3
      metrics = [
        {
          type                 = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
          repositoryNames      = ["logo-solutions/nudger-infra"]
          scaleUpThreshold     = 2
          scaleDownThreshold   = 1
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.runner_deployment]
}
