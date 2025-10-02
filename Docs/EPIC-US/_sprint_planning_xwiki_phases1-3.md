# Sprint Planning – Déploiement XWiki (Phases 1, 2, 3)

## Sprint 1 – Phase 1 : Socle minimal
**Objectif** : Préparer les fondations techniques indispensables (TLS, secrets, ingress).

### Stories
- [ ] Déployer **cert-manager** avec ACME DNS-01 (Cloudflare).
- [ ] Créer Issuer/ClusterIssuer pour `nudger.logo-solutions.fr`.
- [ ] Déployer **ESO (External Secrets Operator)** et configurer intégration avec Vault Bastion.
- [ ] Créer les premiers `ExternalSecret` pour DB et admin XWiki.
- [ ] Déployer **Ingress NGINX** en NodePort.
- [ ] Vérifier certificat TLS valide pour `xwiki.nudger.logo-solutions.fr`.

**Durée estimée** : 1 semaine.  
**Livrable** : Cluster capable de délivrer des secrets depuis Vault et gérer du TLS automatisé.  

---

## Sprint 2 – Phase 2 : Base de données
**Objectif** : Fournir une base de données stable et sécurisée pour XWiki.

### Stories
- [ ] Déployer **MariaDB 10.11** en StatefulSet (hostPath pour tests).
- [ ] Créer schéma `xwiki` et utilisateur applicatif (via ESO + Vault).
- [ ] Configurer charset utf8mb4 et pool de connexions (HikariCP côté app).
- [ ] Mettre en place **NetworkPolicies** : `xwiki → db:3306`, `ingress → xwiki:8080`.
- [ ] Documenter la procédure de connexion DB (runbook).

**Durée estimée** : 1 semaine.  
**Livrable** : Base MariaDB opérationnelle et sécurisée, prête à accueillir XWiki.  

---

## Sprint 3 – Phase 3 : XWiki + Solr
**Objectif** : Déployer XWiki et son moteur de recherche, exposés en HTTPS.

### Stories
- [ ] Déployer **XWiki LTS** (Tomcat) avec variables depuis Vault (ESO).
- [ ] Déployer **Solr** en StatefulSet (index reconstruisible).
- [ ] Configurer readiness/liveness probes pour XWiki et Solr.
- [ ] Créer Ingress HTTPS : `xwiki.nudger.logo-solutions.fr` avec headers sécurité (HSTS, nosniff, CSP simple).
- [ ] Vérifier accès utilisateur final : wiki fonctionnel, cert valide, login admin OK.
- [ ] Documenter runbook “reset mot de passe admin” et “upgrade XWiki”.

**Durée estimée** : 2 semaines.  
**Livrable** : Wiki collaboratif accessible via HTTPS, relié à sa DB et à Solr, utilisable par les utilisateurs finaux.

---

## Vue globale
- **Sprint 1 (sem. 1)** : Socle TLS + secrets + ingress.  
- **Sprint 2 (sem. 2)** : Base de données MariaDB.  
- **Sprint 3 (sem. 3-4)** : XWiki + Solr opérationnels.  

