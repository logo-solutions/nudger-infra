# ADR004 – Gestion du Terraform state
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
Terraform nécessite un fichier d’état (`terraform.tfstate`) pour suivre les ressources créées et leur configuration.  
En local, ce fichier est difficile à partager, vulnérable aux corruptions et limite le travail en équipe.  

Options envisagées :  
- Fichier local (simple mais fragile).  
- Commit Git (mauvaise pratique → secrets + corruption possible).  
- Backend distant (S3 + DynamoDB lock, GCS + lock, Terraform Cloud).  

## Décision
Nous allons utiliser un **backend distant** pour stocker le state (S3 + DynamoDB ou équivalent).  

## Conséquences
- ✅ Collaboration entre plusieurs utilisateurs.  
- ✅ Historique et verrouillage des opérations (`state lock`).  
- ❌ Dépendance au backend (AWS, GCP ou Terraform Cloud).  
- ❌ Complexité d’initialisation supplémentaire.  

---
