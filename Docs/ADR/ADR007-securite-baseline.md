# ADR007 – Sécurité et durcissement Kubernetes
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
Le cluster Kubernetes doit être sécurisé contre les déploiements non conformes.  
Deux mécanismes principaux :  
- Pod Security Admission (PSA).  
- Kyverno (policies de validation).  

## Décision
Nous adoptons :  
- **PSA Baseline** appliqué par défaut.  
- **Kyverno** pour des règles complémentaires (par ex. : forcer les labels, interdire `:latest`).  
- **Cert-manager** pour gestion TLS automatique (Let’s Encrypt).  

## Conséquences
- ✅ Sécurité renforcée.  
- ✅ Cohérence des workloads.  
- ❌ Augmente la complexité des déploiements (besoin d’adapter certains manifests).  

---
