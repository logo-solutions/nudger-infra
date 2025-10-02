# ADR003 – Utilisation de Vault pour les secrets
**Date** : 2025-09-26  
**Statut** : Proposé (à implémenter)  

## Contexte
Aujourd’hui les secrets sont dispersés :  
- **Ansible Vault** pour certaines variables sensibles.  
- **Fichiers YAML commités** avec des placeholders ou des secrets faibles.  
- **Secrets GitHub** pour l’automatisation.  

Ce modèle crée un risque de duplication, une rotation difficile et un manque d’auditabilité.  

## Décision
Nous allons centraliser les secrets dans **HashiCorp Vault**, qui deviendra la source de vérité :  
- Terraform utilisera le provider `vault` pour récupérer ses secrets.  
- Ansible utilisera `lookup('hashi_vault', ...)` pour injecter au runtime.  
- Kubernetes pourra synchroniser certains secrets via CSI driver ou opérateur Vault.  

## Conséquences
- ✅ Secrets centralisés et audités.  
- ✅ Rotation et révocation facilitées.  
- ✅ Réduction du nombre de secrets stockés en clair dans Git.  
- ❌ Ajoute de la complexité (maintenance d’un service Vault hautement dispo).  
- ❌ Dépendance forte à Vault pour le bootstrap → nécessite un plan B en cas d’indisponibilité.  

---
