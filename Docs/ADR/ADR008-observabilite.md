# ADR008 – Observabilité et monitoring
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
Un cluster de production nécessite supervision (métriques, logs, dashboards).  
Options :  
- Prometheus + Grafana + Loki.  
- Solutions managées externes (Datadog, NewRelic).  

## Décision
Nous adoptons la stack **Prometheus Operator + Loki + Grafana** déployée via Terraform (provider `helm`).  

## Conséquences
- ✅ Stack open-source cohérente et éprouvée.  
- ✅ Dashboards préconfigurés pour Kubernetes et Longhorn.  
- ❌ Consommation de ressources (RAM/CPU).  
- ❌ Maintenance des mises à jour charts/alertes.  

---
