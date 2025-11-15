terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
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
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# -----------------------------------------------------------------------------
# Prometheus
# -----------------------------------------------------------------------------
resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.8.0"

  values = [
    yamlencode({
      alertmanager = { enabled = false }
      pushgateway  = { enabled = false }

      server = {
        global = {
          scrape_interval = "30s"
        }
        service = {
          type = "ClusterIP"
          port = 9090
        }
      }

      extraScrapeConfigs = <<-EOT
        - job_name: 'kube-state-metrics'
          static_configs:
          - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']

        - job_name: 'metrics-server'
          static_configs:
          - targets: ['metrics-server.kubernetes-dashboard.svc.cluster.local:443']
      EOT
    }),

    file("${path.module}/prometheus-values-hardening.yaml")
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# -----------------------------------------------------------------------------
# Grafana
# -----------------------------------------------------------------------------
resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.6.1"

  values = [
    yamlencode({
      adminUser     = "admin"
      adminPassword = "admin"
      service = {
        type     = "NodePort"
        nodePort = 30300
      }

      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server.monitoring.svc.cluster.local"
              access    = "proxy"
              isDefault = true
            }
          ]
        }
      }

      persistence = {
        enabled = true
        size    = "2Gi"
      }
    }),

    file("${path.module}/grafana-values-hardening.yaml")
  ]

  depends_on = [helm_release.prometheus]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "grafana_access" {
  value = {
    url      = "http://<NODE_IP>:30300"
    username = "admin"
    password = "admin"
  }
}

output "prometheus_access" {
  value = {
    url = "http://prometheus-server.monitoring.svc.cluster.local:9090"
  }
}
