# 🧾 ADR008 – Observabilité et monitoring (version allégée)

**Date :** 2025-09-26  
**Statut :** 🟢 Adopté (version adaptée à la production simplifiée)

---

## 🎯 Contexte

L’objectif est d’assurer un niveau d’observabilité cohérent avec la taille et les besoins actuels du projet **Nudger / XWiki**, sans introduire de complexité inutile.  
Le client souhaite **éviter la stack Prometheus + Grafana + Loki**, jugée trop lourde pour une première phase d’exploitation.  

Le cluster reste de taille modeste (1 à 3 nœuds) et ne justifie pas la mise en place d’un écosystème complet de métriques et d’alertes.

---

## ⚙️ Alternatives retenues

### 1. Composants natifs Kubernetes

- **metrics-server** → expose les métriques CPU et mémoire via `kubectl top`.  
- **kube-state-metrics** → permet de surveiller l’état général du cluster et des ressources.  
- **kubectl logs / k9s / Lens** → lecture et navigation dans les logs sans outil externe.  
- **journalctl** → diagnostic au niveau des nœuds.  

Ces outils couvrent **80 % des besoins courants** pour un petit cluster :  
vérification de charge, état des pods, suivi des namespaces et inspection rapide en cas d’erreur.

---

## 🧩 Décision

### 🧪 Phase intégration / recette
- Utilisation **exclusivement des outils natifs** Kubernetes (metrics-server, kube-state-metrics, kubectl logs).  
- Accès via `kubectl`, `k9s` ou `Lens` depuis le poste d’administration.  
- Pas d’installation de stack lourde (Prometheus, Grafana, Loki).  
- Logging local géré via `containerd` et inspection ponctuelle via CLI.

### ⚙️ Phase production
- Maintien du **même modèle simplifié**, avec quelques automatisations supplémentaires :  
  - script `sanitycheck` pour tester l’état du cluster,  
  - alertes basiques par cron (vérification de pods en erreur).  
- Sauvegarde des logs critiques des applications (ex. XWiki, MySQL) sur volume persistant.  
- En cas de montée en charge future → possibilité d’ajouter la stack Prometheus + Grafana + Loki.

---

## ⚖️ Avantages et inconvénients

| Type | Détails |
|------|----------|
| ✅ **Avantages** | - Très faible empreinte sur les ressources du cluster.<br>- Maintenance quasi nulle.<br>- Accès direct aux données via les commandes Kubernetes.<br>- Déploiement instantané, sans Helm chart supplémentaire.<br>- Adapté à un usage mono-application (XWiki). |
| ⚠️ **Inconvénients** | - Pas d’historisation longue durée.<br>- Pas de dashboards consolidés.<br>- Absence d’alerting avancé ou de corrélation logs/métriques.<br>- Supervision essentiellement manuelle. |

---

## 🧭 Recommandation finale

| Environnement | Stack observabilité | Objectif | Charge |
|----------------|--------------------|-----------|--------|
| **Intégration** | `metrics-server`, `kube-state-metrics`, `kubectl logs` | Suivi basique | ⚡ Très légère |
| **Recette** | idem + usage de `Lens` ou `k9s` | Validation fonctionnelle | ⚡ Légère |
| **Production** | mêmes outils + scripts de vérification périodiques | Supervision manuelle adaptée | ⚡ Légère |

Cette approche permet de **livrer une production fonctionnelle, maintenable et simplifiée**, tout en laissant la porte ouverte à une future montée en puissance (intégration de Prometheus/Grafana/Loki si besoin).

---

**Rédacteur :** Loïc Bourmelon  
**Revu par :** Thomas Toussaint  
**Dernière mise à jour :** 2025-11-04

