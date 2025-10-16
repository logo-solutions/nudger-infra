output "storageclass_default" {
  value       = "longhorn"
  description = "Nom du StorageClass par défaut créé"
}

output "longhorn_namespace" {
  value       = "longhorn-system"
  description = "Namespace de Longhorn"
}
