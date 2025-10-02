# ADR008 – Observabilité et monitoring
**Date** : 2025-09-26  
**Statut** : Accepté (mis à jour)

## Contexte
Un cluster de production nécessite supervision (métriques, logs, dashboards).  
Mais les besoins diffèrent fortement entre un environnement de test (1 nœud, ressources limitées) et une production stable.

Options :
- **Phase tests** : métriques et logs basiques.  
- **Phase prod** : stack complète open-source (Prometheus, Grafana, Loki).  
- **Solutions externes** (Datadog, NewRelic).

## Décision
- En **phase tests** : nous déployons seulement les composants minimaux :  
  - `metrics-server` pour usage `kubectl top`,  
  - `kube-state-metrics` pour état du cluster,  
  - logs locaux via container runtime.  

- En **phase prod** : nous déploierons la stack complète **Prometheus Operator + Grafana + Loki**, avec dashboards préconfigurés et alertes.

## Conséquences
- ✅ Phase tests : faible consommation de ressources, simplicité.  
- ✅ Phase prod : observabilité complète, alertes et dashboards robustes.  
- ❌ Besoin de migration/ajout de composants lors du passage en prod.  
- ❌ Maintenance des mises à jour charts/alertes en prod.
