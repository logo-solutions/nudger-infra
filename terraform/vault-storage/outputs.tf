output "pv_name" {
  value       = kubernetes_persistent_volume.vault_data.metadata[0].name
  description = "Nom du PersistentVolume créé"
}

output "pvc_name" {
  value       = kubernetes_persistent_volume_claim.vault_data_claim.metadata[0].name
  description = "Nom du PersistentVolumeClaim créé"
}

output "vault_namespace" {
  value       = kubernetes_namespace.vault.metadata[0].name
  description = "Namespace associé à Vault"
}
