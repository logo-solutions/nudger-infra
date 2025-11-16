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

  # 1) Overrides dynamiques spécifiques à ton cluster
  values = [
    yamlencode({
      # Tu restes maître sur l’alertmanager
      alertmanager = {
        enabled = false
      }
"prometheus-pushgateway" = {
  enabled = true

  podSecurityContext = {
    runAsUser    = 65534
    runAsNonRoot = true
    fsGroup      = 65534
  }

  containerSecurityContext = {
    runAsNonRoot             = true
    runAsUser                = 65534
    allowPrivilegeEscalation = false
    readOnlyRootFilesystem   = true
    capabilities = {
      drop = ["ALL"]
    }
  }

  resources = {
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "128Mi"
    }
  }
}

      # Jobs supplémentaires si tu veux garder ton kube-state-metrics + metrics-server statiques
      extraScrapeConfigs = <<-EOT
        - job_name: 'kube-state-metrics'
          static_configs:
          - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']

        - job_name: 'metrics-server'
          static_configs:
          - targets: ['metrics-server.kubernetes-dashboard.svc.cluster.local:443']
      EOT

      # Désactivation explicite du hostNetwork/hostPID/hostIPC pour le node-exporter
      "prometheus-node-exporter" = {
        hostNetwork = false
        hostPID     = false
        hostIPC     = false
      }
    }),

    # 2) Tout le HARDENING CPU/MEM + securityContext (dont pushgateway)
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

      # HARDENING GRAFANA
      securityContext = {
        runAsNonRoot             = true
        runAsUser                = 65534
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        capabilities = {
          drop = ["ALL"]
        }
      }

      resources = {
        requests = {
          cpu    = "200m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      serviceAccount = {
        automountServiceAccountToken = false
      }

      sidecar = {
        datasources = { enabled = false }
        dashboards  = { enabled = false }
      }
    })
  ]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

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
