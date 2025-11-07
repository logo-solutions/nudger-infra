output "namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}
