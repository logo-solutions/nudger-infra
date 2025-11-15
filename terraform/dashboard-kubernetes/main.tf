terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

locals {
  namespace     = "kubernetes-dashboard"
  domain        = "dashboard.nudger.logo-solutions.fr"
  tls_secret    = "secret-tls-dashboard"
  chart_name    = "kubernetes-dashboard"
  chart_repo    = "https://kubernetes.github.io/dashboard/"
  chart_version = "6.0.8"
  admin_account = "kubernetes-dashboard-admin"
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "dashboard" {
  metadata {
    name = local.namespace
  }
}

# -----------------------------------------------------------------------------
# Helm release
# -----------------------------------------------------------------------------
resource "helm_release" "dashboard" {
  name            = local.chart_name
  repository      = local.chart_repo
  chart           = local.chart_name
  namespace       = kubernetes_namespace.dashboard.metadata[0].name
  version         = local.chart_version
  cleanup_on_fail = true

  set = [
    # Ingress
    { name = "ingress.enabled", value = "true" },
    { name = "ingress.className", value = "nginx" },
    { name = "ingress.hosts[0]", value = local.domain },
    { name = "ingress.tls[0].hosts[0]", value = local.domain },
    { name = "ingress.tls[0].secretName", value = local.tls_secret },

    # Service
    { name = "service.type", value = "ClusterIP" },

    # Metrics
    { name = "metricsScraper.enabled", value = "true" },
    { name = "metrics-server.enabled", value = "true" },
    { name = "metrics-server.args[0]", value = "--kubelet-insecure-tls=true" },

    # RBAC
    { name = "rbac.clusterReadOnlyRole", value = "true" },
    { name = "extraArgs[0]", value = "--enable-skip-login" }
  ]

  values = [
    file("${path.module}/dashboard-metrics-scraper-hardening.yaml")
  ]

  depends_on = [
    kubernetes_namespace.dashboard
  ]
}

# -----------------------------------------------------------------------------
# Admin ServiceAccount + RBAC
# -----------------------------------------------------------------------------
resource "kubernetes_service_account" "admin" {
  metadata {
    name      = local.admin_account
    namespace = local.namespace
  }
}

resource "kubernetes_cluster_role_binding" "admin_role_binding" {
  metadata {
    name = local.admin_account
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin.metadata[0].name
    namespace = local.namespace
  }
}

resource "kubernetes_secret" "admin_token" {
  metadata {
    name      = "${local.admin_account}-token"
    namespace = local.namespace
    annotations = {
      "kubernetes.io/service-account.name" = local.admin_account
    }
  }
  type = "kubernetes.io/service-account-token"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "dashboard_url" {
  value = "https://${local.domain}"
}

output "admin_service_account" {
  value = local.admin_account
}

output "namespace" {
  value = local.namespace
}

output "admin_token" {
  value     = kubernetes_secret.admin_token.data["token"]
  sensitive = true
}
