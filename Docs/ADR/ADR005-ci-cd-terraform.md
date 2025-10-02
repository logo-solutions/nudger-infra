# ADR005 – Stratégie CI/CD Terraform
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
Le cluster est désormais géré via Terraform (remplacement de FluxCD).  
Il faut définir une stratégie de déploiement et de validation :  
- Exécution manuelle sur laptop ?  
- GitHub Actions automatisé ?  
- Validation par PR ?  

## Décision
Nous adoptons une approche CI/CD via GitHub Actions :  
- `terraform fmt` et `terraform validate` sur chaque PR.  
- `terraform plan` sur chaque PR avec sortie commentée.  
- `terraform apply` déclenché uniquement après merge sur `main`, via job validé manuellement.  

## Conséquences
- ✅ Plus de transparence sur les changements (`plan` publié en CI).  
- ✅ Réduction du drift entre infra réelle et code.  
- ❌ Ajoute un besoin en secrets GitHub (provider credentials).  
- ❌ Allonge la durée des PR (temps de `plan`).  

---
