# ADR002 – Remplacer FluxCD par Terraform pour la gestion des manifestes Kubernetes
**Date** : 2025-09-26  
**Statut** : Accepté  

## Contexte
FluxCD était utilisé pour appliquer les Kustomizations et HelmRelease directement depuis Git.  
Cependant :  
- Logs difficiles à analyser en cas d’échec (`context deadline exceeded`).  
- Dépendances implicites entre Kustomizations (cert-manager avant ingress-nginx).  
- Secrets GitHub injectés dans le cluster (surface d’attaque).  

## Décision
Nous adoptons **Terraform** pour la gestion des ressources Kubernetes :  
- provider `helm` pour ingress-nginx, cert-manager, longhorn.  
- provider `kubernetes` pour namespaces, secrets, ConfigMaps.  
- modules dédiés pour les apps (XWiki, MySQL).  

## Conséquences
- ✅ Simplicité de debug (`terraform plan/apply`).  
- ✅ Un seul état global (Terraform state).  
- ✅ Suppression des pods Flux dans le cluster → infra plus légère.  
- ❌ Pas de GitOps pull → il faut déclencher `terraform apply` manuellement ou via CI/CD.  
- ❌ Ordonnancement explicite des dépendances à gérer (`depends_on`).  

---
