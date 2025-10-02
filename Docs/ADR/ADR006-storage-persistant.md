# ADR006 – Stockage persistant Kubernetes
**Date** : 2025-09-26  
**Statut** : Accepté (mis à jour)

## Contexte
XWiki/MySQL nécessitent du stockage persistant. Actuellement : PV Local Path.  
En cas de recréation VM, risque de perte des données.

Options :
- **Local Path** (rapide mais pas tolérant aux pannes).
- **Longhorn** (réplication, snapshots, backups).
- **Externalisé** (RDS, Cloud SQL).

## Décision
- En **phase de test (1 seul nœud)** : nous utilisons **Local Path** (plus simple, pas de surcoût inutile).  
- En **phase multi-nœuds** : nous activerons **Longhorn** comme solution de stockage persistant par défaut (réplication intra-cluster).  
- Les bases critiques (MySQL pour XWiki) seront sauvegardées régulièrement vers un backend externe (S3) une fois Longhorn activé.

## Conséquences
- ✅ Simplicité en environnement de test (pas de complexité inutile).
- ✅ Résilience accrue dès passage au multi-nœuds (réplication, snapshots).  
- ✅ Sauvegardes vers backend externe prévues à terme.  
- ❌ Complexité opérationnelle (maintenance de Longhorn).  
- ❌ Consommation disque plus élevée en prod (réplication).
