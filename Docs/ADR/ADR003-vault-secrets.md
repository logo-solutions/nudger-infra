# 🧾 ADR003 – Gestion centralisée des secrets avec Bitwarden

**Date :** 2025-09-26  
**Statut :** 🟢 Adopté (en cours de déploiement)

---

## 🎯 Contexte

Initialement, le projet prévoyait d’utiliser **HashiCorp Vault** comme solution centralisée de gestion des secrets.  
Cependant, ce choix impliquait la mise en place d’une infrastructure supplémentaire (Vault HA, stockage backend, authentification tokens, etc.) peu adaptée à la taille de l’équipe actuelle et à la complexité du projet.

Aujourd’hui, les secrets sont éparpillés entre :
- **Ansible Vault** (pour certaines variables sensibles),
- **YAML commités** avec placeholders ou secrets temporaires,
- **Secrets GitHub Actions** (pour les workflows d’automatisation).

Ce modèle présente :
- une **duplication** des valeurs sensibles,  
- une **rotation manuelle** fastidieuse,  
- et un **manque d’auditabilité**.

---

## ✅ Décision

Nous avons décidé de **centraliser la gestion des secrets dans Bitwarden**, qui devient la **source de vérité unique** pour tous les environnements.

### Implémentation prévue

- **Terraform** : utilisation de `bw get item` et de `jq` pour injecter dynamiquement les secrets Cloudflare, Hetzner, etc.  
- **Ansible** : récupération des secrets via `lookup('pipe', 'bw get item <nom>')` ou export préalable du `BW_SESSION`.  
- **GitHub Actions / ARC** : génération des secrets CI/CD directement depuis Bitwarden (scripts Bash automatisés).  
- **Kubernetes** : synchronisation des secrets applicatifs par script (`kubectl create secret generic ...`) en s’appuyant sur Bitwarden comme backend.

---

## ⚙️ Conséquences

### ✅ Avantages
- **Centralisation** : un seul coffre pour tous les secrets (Terraform, Ansible, CI/CD, etc.).  
- **Simplicité d’usage** : Bitwarden est hébergé et ne nécessite pas de cluster HA.  
- **Auditabilité** : traçabilité des accès et des modifications via le coffre Bitwarden.  
- **Automatisation** : intégration simple dans les scripts existants (`bw get`, `jq`, `export BW_SESSION`).  
- **Portabilité** : compatible avec MacOS, Linux, et CI runners.

### ⚠️ Inconvénients
- **Dépendance à Bitwarden Cloud** (ou auto-hébergé si nécessaire).  
- **Authentification manuelle requise** pour obtenir le `BW_SESSION` dans certains cas non automatisés.  
- **Absence de moteur de rotation automatique** des secrets (rotation manuelle ou scriptée).

---

## 🧩 Alternatives considérées

| Option | Raisons de non-adoption |
|--------|--------------------------|
| **HashiCorp Vault** | Trop complexe à maintenir pour une équipe réduite, nécessite stockage et backend HA. |
| **SOPS + GPG** | Simple mais sans gestion multi-utilisateur ni audit. |
| **GitHub Secrets** | Restreint aux workflows GitHub et non adapté à l’usage Terraform/Ansible. |

---

## 🧭 Conclusion

Bitwarden offre un **équilibre optimal** entre sécurité, simplicité et intégration dans les outils existants.  
Il est adopté comme **backend officiel de gestion des secrets** pour tous les composants du projet (Terraform, Ansible, Kubernetes, CI/CD).

