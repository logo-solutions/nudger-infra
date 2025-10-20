###############################################
# Providers
###############################################

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
  backend "local" {
    path = "/root/.terraform/xwiki/terraform.tfstate"
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

###############################################
# Variables
###############################################

variable "dns_zone" {
  description = "Nom du domaine principal"
  type        = string
}

variable "email" {
  description = "Adresse email utilisée pour Let's Encrypt"
  type        = string
}

###############################################
# Namespace XWiki
###############################################

resource "kubernetes_namespace" "xwiki" {
  metadata {
    name = "xwiki"
  }
}

###############################################
# Helm Chart XWiki
###############################################

resource "helm_release" "xwiki" {
  name       = "xwiki"
  namespace  = kubernetes_namespace.xwiki.metadata[0].name
  repository = "https://xwiki-contrib.github.io/xwiki-helm"
  chart      = "xwiki"
  version    = "1.1.2" # à adapter selon ta version stable

values = [yamlencode({
  mysql = {
    enabled = true
    image = {
      registry   = "public.ecr.aws"
      repository = "bitnami/mysql"
      tag        = "8.4.5-debian-12-r0"
      pullPolicy = "IfNotPresent"
    }
    auth = {
      username     = "xwiki"
      password     = "xwiki"
      database     = "xwiki"
      rootPassword = "root"
    }
  }

  ingress = {
    enabled  = true
    className = "nginx"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-dns"
    }
    hosts = [{
      host = "wiki.logo-solutions.fr"
      paths = [{
        path     = "/"
        pathType = "Prefix"
      }]
    }]
    tls = [{
      hosts      = ["wiki.logo-solutions.fr"]
      secretName = "tls-xwiki"
    }]
  }

  resources = {
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
    requests = {
      cpu    = "200m"
      memory = "512Mi"
    }
  }
})]
  depends_on = [
    kubernetes_namespace.xwiki,
  ]
}

###############################################
# Sortie utile
###############################################

output "xwiki_ingress_url" {
  description = "URL d’accès à XWiki"
  value       = "https://wiki.${var.dns_zone}"
}
