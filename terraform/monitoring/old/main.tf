terraform {
  required_version = "~> 1.2"  # Assurez-vous de spécifier la version de Terraform utilisée
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"  # Version compatible avec votre configuration
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"  # Compatible avec Kubernetes v1.31.13
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
# Namespace monitoring
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
    }
  }
}

# -----------------------------------------------------------------------------
# Prometheus Service
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "prometheus_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "prometheus-server"
      namespace = "monitoring"
    }
    spec = {
      selector = {
        app = "prometheus"
      }
      ports = [
        {
          port     = 9090
          protocol = "TCP"
          targetPort = 9090
        }
      ]
      type = "LoadBalancer"
    }
  }
}

# -----------------------------------------------------------------------------
# Ingress for Prometheus and Grafana
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Grafana Service
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "grafana_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "grafana"
      namespace = "monitoring"
    }
    spec = {
      selector = {
        app = "grafana"
      }
      ports = [
        {
          port     = 80
          protocol = "TCP"
          targetPort = 80
        }
      ]
      type = "LoadBalancer"
    }
  }
}

# -----------------------------------------------------------------------------
# kube-prometheus-stack — Prometheus Operator
# -----------------------------------------------------------------------------
resource "helm_release" "kps" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "60.3.0"  # Version stable et compatible

  cleanup_on_fail = true

  values = [
    file("${path.module}/prometheus-values-hardening.yaml"),
    file("${path.module}/grafana-values-hardening.yaml")
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "grafana_infos" {
  value = {
    url      = "http://<NODE_IP>:30300"
    username = "admin"
    password = "admin"
  }
}

output "prometheus_url" {
  value = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
}
