# Spécification Technique – Déploiement XWiki (Phase Tests, État mis à jour)

## 1. Contexte & Objectifs
- Hébergement de XWiki sur Kubernetes (VPS Hetzner).
- Cluster K8s **déjà monté via Ansible** (Flannel CNI).
- Exposition à Internet via domaine `nudger.logo-solutions.fr` (Cloudflare actif, DNS configuré).
- Vault déjà déployé sur Bastion (centralisation des secrets).
- Objectif métier : portail documentaire collaboratif, accessible aux utilisateurs finaux.
- Phase actuelle = environnement de test (1 nœud), évolutif vers multi-nœuds.

## 2. Architecture Globale
- **Kubernetes** : cluster existant (Flannel, géré via Ansible).
- **DNS & TLS** : Cloudflare (proxy + WAF + DNS), cert-manager (ACME DNS-01) à déployer.
- **Secrets** : HashiCorp Vault (Bastion) + External Secrets Operator (ESO) à connecter au cluster.
- **Stockage** : 
  - Actuel : hostPath. 
  - Optionnel (flag Terraform) : Longhorn (réplication et HA quand plusieurs nœuds).
- **Base de données** : MariaDB 10.11 (StatefulSet K8s, 1 réplique, pas de sauvegardes initialement).
- **XWiki** : version LTS, Tomcat, Solr séparé en StatefulSet.
- **Observabilité** : metrics basiques (metrics-server, kube-state-metrics), pas de Grafana. Logs stockés localement.
- **Sécurité** : Cloudflare WAF/DDoS déjà en place, NetworkPolicies strictes à mettre en œuvre, Pod Security “restricted”, TLS 1.2+.

## 3. Organisation & Nommage
- **Namespaces** : `xwiki`, `db`, `solr`, `ingress`, `cert-manager`, `external-dns`, `vault`, `observability`.
- **Convention de nommage** : `{env}-{svc}-{component}-{seq}` (ex. `dev-xwiki-app-01`).
- **Labels/Tags obligatoires** : `owner`, `env`, `costcenter`, `data_class`, `compliance`.
- **Arborescence de repo** :
  - `/terraform/envs/{dev,preprod,prod}`
  - `/terraform/modules/{network,k8s,ingress,longhorn,db,xwiki,solr,monitoring,dns,cf}`
  - `/k8s/helm-values/{dev,preprod,prod}`
  - `/docs/{runbooks,adr,security}`

## 4. Sécurité & Conformité
- Secrets déjà centralisés dans Vault (Bastion). Intégration via ESO au cluster K8s à réaliser.
- TLS à automatiser via cert-manager (ACME DNS-01 avec Cloudflare).
- Cloudflare devant Ingress NGINX (proxy orange, WAF, DDoS, cache statique).
- Accès SSH via bastion, MFA obligatoire. Aucun accès direct DB/3306 depuis Internet.
- NetworkPolicies à appliquer par namespace (deny-all + règles ciblées).

## 5. Stockage & Données
- Actuel : PVCs hostPath (XWiki 20 Go, DB 10 Go, Solr 5 Go).
- Préparation pour Longhorn : réplication, snapshots, migration simple quand multi-nœuds disponibles.
- Sauvegardes DB désactivées au départ (flag Terraform `enable_db_backups = false`).
- Rétention/logique PRA à activer plus tard avec Velero + sauvegardes DB (XtraBackup/binlogs).

## 6. Observabilité & Journaux
- Metrics basiques : CPU/mémoire pods/nœuds, état objets K8s.
- Logs : rotation locale via container runtime, consultation avec `kubectl logs`.
- Alerting : non activé au départ (prévu plus tard via Prometheus + Alertmanager).

## 7. Gouvernance & Runbooks
- **Environnements** : dev → preprod → prod.
- **Runbooks initiaux** : 
  - connexion ESO-Vault,
  - déploiement cert-manager,
  - déploiement XWiki + DB + Solr,
  - passage à Longhorn quand multi-nœuds,
  - activation des sauvegardes DB,
  - rotation des secrets.
- **Maintenances** : patch mensuel (OS/K8s/app), fenêtres planifiées (ex. mardi 20h–22h).
- **Accès admin** : comptes break-glass hors ligne, rotation des secrets via Vault, MFA obligatoire.

## 8. Migration & Évolutivité
- Ajout de nœuds K8s → activation Longhorn (flag Terraform).
- Activation progressive des sauvegardes DB et Velero (flag Terraform).
- Passage de la DB en VM dédiée (Hetzner) ou cluster Galera si SLA > 99.5% requis.
- Activation Grafana/Loki si besoin de dashboards/logs centralisés.

---

**Statut actuel :**  
- Cluster K8s déjà déployé via Ansible (Flannel).  
- DNS et Cloudflare opérationnels.  
- Vault opérationnel sur Bastion.  
- Prochaines étapes = intégration ESO-Vault, cert-manager, déploiement XWiki/DB/Solr.  
