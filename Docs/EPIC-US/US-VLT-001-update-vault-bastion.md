# User Story – Mise à jour de Vault Bastion pour compatibilité Kubernetes masters

## ID
US-VLT-001

## Titre
Mettre à jour et configurer Vault (Bastion) pour permettre l’intégration sécurisée avec les masters Kubernetes.

## Contexte
- Vault est actuellement déployé sur le Bastion, en mode standalone.  
- Les masters Kubernetes doivent accéder à Vault pour obtenir leurs secrets (via External Secrets Operator).  
- Aujourd’hui, l’authentification Kubernetes n’est pas encore activée dans Vault.  

## En tant que
Ingénieur plateforme,

## Je veux
Mettre à jour et configurer Vault sur le Bastion afin qu’il expose une méthode d’authentification Kubernetes sécurisée et compatible avec mes masters,

## Afin de
- Centraliser la gestion des secrets pour toutes les applications K8s.  
- Éviter la duplication des secrets et réduire les risques de fuite.  
- Permettre une rotation et une auditabilité des secrets utilisés par Kubernetes.

## Critères d’acceptation
- [ ] Vault est mis à jour vers une version supportant `auth/kubernetes`.  
- [ ] Le plugin `auth/kubernetes` est activé et configuré pour pointer vers l’API server des masters.  
- [ ] Une **policy** dédiée (`xwiki-read`) est créée pour restreindre l’accès aux secrets du namespace XWiki.  
- [ ] Une **role** Vault est créée liant la policy à un ServiceAccount ESO dans Kubernetes.  
- [ ] Les masters peuvent obtenir un secret depuis Vault via ESO (test : DB password injecté dans namespace `xwiki`).  
- [ ] La documentation d’intégration (steps bootstrap + runbook) est disponible dans `/docs/runbooks/vault-integration.md`.  
- [ ] Logs d’accès Vault activés et auditables (au minimum fichier local, idéalement backend syslog/ELK).

## Dépendances
- ESO (External Secrets Operator) déployé dans le cluster K8s.  
- DNS/connexion réseau entre Bastion (Vault) et masters (port TCP/8200).  
- Certificat TLS valide pour Vault, ou CA importée côté cluster.

## Effort estimé
8 points (inclut mise à jour, configuration auth, création policies/roles, test end-to-end).

