# Backlog Produit – Déploiement XWiki (Phase Tests, État mis à jour)

| ID | User Story (résumé)                | Priorité | Estimation (pts) |
|----|-------------------------------------|----------|------------------|
| 1  | Déployer cert-manager               | Haute    | 5 |
| 2  | Intégrer Vault (Bastion) avec ESO   | Haute    | 8 |
| 3  | Installer Ingress NGINX (cluster)   | Haute    | 5 |
| 4  | Déployer MariaDB StatefulSet        | Haute    | 8 |
| 5  | Déployer XWiki LTS (Tomcat)         | Haute    | 13 |
| 6  | Déployer Solr pour XWiki            | Moyenne  | 5 |
| 7  | Configurer Secrets (DB, admin)      | Haute    | 5 |
| 8  | Configurer TLS certs Ingress        | Haute    | 3 |
| 9  | Activer NetworkPolicies de base     | Moyenne  | 5 |
| 10 | Configurer métriques basiques       | Moyenne  | 3 |
| 11 | Activer logs locaux (rotation)      | Moyenne  | 3 |
| 12 | Créer runbook bootstrap             | Moyenne  | 5 |
| 13 | Flag Terraform Longhorn             | Basse    | 8 |
| 14 | Flag Terraform Backups DB           | Basse    | 8 |
| 15 | Mise en place SMTP                  | Basse    | 5 |
| 16 | Ajout tests de santé (synthetic)    | Basse    | 5 |
| 17 | Préparer migration multi-nœuds      | Basse    | 13 |

---

**Statut actuel :**
- ✅ Cluster K8s déployé via Ansible (Flannel).  
- ✅ Cloudflare et DNS opérationnels.  
- ✅ Vault installé sur Bastion.  

**Prochaines étapes clés :**
1. cert-manager + ESO-Vault  
2. Ingress NGINX + TLS  
3. DB + XWiki + Solr  
