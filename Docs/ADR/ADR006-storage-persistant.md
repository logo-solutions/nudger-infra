# ADR006 – Stockage persistant Kubernetes
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
XWiki/MySQL nécessitent du stockage persistant. Actuellement : PV local path.  
En cas de recréation VM, risque de perte des données.  

Options :  
- **Local Path** (rapide mais pas tolérant aux pannes).  
- **Longhorn** (réplication, snapshots, backups).  
- **Externalisé** (RDS, Cloud SQL).  

## Décision
Nous adoptons **Longhorn** comme solution de stockage persistant par défaut.  
Les bases critiques (MySQL pour XWiki) seront sauvegardées régulièrement vers un backend externe (S3).  

## Conséquences
- ✅ Résilience accrue (réplication intra-cluster).  
- ✅ Sauvegardes vers backend externe.  
- ❌ Complexité opérationnelle (maintenance de Longhorn).  
- ❌ Consommation disque plus élevée (réplication).  

---
