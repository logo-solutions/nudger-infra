# ADR010 – Architecture de gestion des secrets : Vault Bastion ↔ Vault Kubernetes ↔ Terraform

**Date :** 2025-10-13  
**Auteur :** Loïc Bourmelon  
**Statut :** ✅ Acceptée  
**Version :** 1.0

---

## 🎯 Contexte

Le projet **Nudger-VM / Nudger-Infra** dispose désormais :
- d’un **Bastion** (VM Hetzner) hébergeant les outils DevOps (Ansible, Terraform, Vault, etc.)
- d’un **cluster Kubernetes** (namespace `xwiki`, `vault`, etc.)
- d’un **déploiement XWiki/MySQL** géré par Terraform via le chart Helm officiel.

Deux instances de **HashiCorp Vault** coexistent :

| Instance | Localisation | Rôle principal |
|-----------|--------------|----------------|
| `Vault Bastion` | VM Bastion | Source de vérité (secrets initiaux, tokens Hetzner, GitHub, Cloudflare, MySQL root, etc.) |
| `Vault K8s` | Cluster Kubernetes (namespace `vault`) | Fournit les secrets dynamiques aux applications via Vault Agent / CSI Driver |

---

## 🧩 Décision

1. **Le Vault Bastion** reste l’unique **source de vérité centrale**.
   - Il est initialisé et unsealed via Ansible (`/root/.ansible/artifacts/bastion/vault-init.json`).
   - Il contient les secrets sensibles partagés à travers l’infrastructure :
     - `HCLOUD_TOKEN`, `CF_API_TOKEN`, `MYSQL_ROOT_PASSWORD`, `XWIKI_DB_PASSWORD`, etc.
   - C’est cette instance qui alimente Terraform et Vault-K8s.

2. **Le Vault Kubernetes** n’est qu’un **miroir opérationnel**, non une autorité.
   - Il est déployé via Ansible/Helm (namespace `vault`).
   - Il est initialisé par Ansible (`21-vault_k8s_post_init.yml`).
   - Il reçoit un sous-ensemble de secrets depuis le Bastion (`22-vault_seed.yml`).
   - Il sert aux workloads applicatifs (XWiki, cert-manager, etc.).

3. **Terraform doit s’exécuter depuis le Bastion** :
   - Accès local au Vault (`http://127.0.0.1:8200`).
   - Token root disponible dans l’environnement :
     ```bash
     export VAULT_TOKEN=$(jq -r .root_token /root/.ansible/artifacts/bastion/vault-init.json)
     ```
   - Provider `vault` configuré avec ce token.

---

## ⚙️ Implémentation

### 📦 Provider Terraform Vault

```hcl
provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_kv_secret_v2" "mysql_root" {
  mount = "secret"
  name  = "mysql/root"
}
