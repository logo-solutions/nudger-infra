output "storage_class_default" {
  description = "StorageClass utilisé par défaut pour les volumes dynamiques"
  value       = "local-path"
}

output "namespace" {
  description = "Namespace du local-path-provisioner"
  value       = kubernetes_namespace.local_path.metadata[0].name
}
