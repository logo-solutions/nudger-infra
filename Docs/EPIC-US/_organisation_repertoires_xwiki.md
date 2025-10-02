# Organisation des répertoires – Mono‑repo Terraform / Apps / Infra (XWiki)

> Objectif : décrire **où va quoi** (Terraform, Helm/apps, Ansible, observabilité, docs) pour un déploiement XWiki sur K8s (Flannel, Ingress‑NGINX), DNS/Proxy Cloudflare, secrets Vault/ESO.  
> Remarque : **pas de code**, uniquement la structure et le rôle de chaque dossier.

---

## 0) Vue d’ensemble (top‑level)

```
repo-root/
├─ terraform/                 # Infra as Code (cluster déjà en place, mais tout le reste ici)
├─ k8s/                       # Manifests Helm/values + config applicative K8s
├─ apps/                      # Assets applicatifs (XWiki, Solr), confs fonctionnelles
├─ ansible/                   # Playbooks/roles déjà utilisés pour bootstrap cluster
├─ ops/                       # Observabilité, sécurité K8s, politiques réseau/PSA
├─ docs/                      # Runbooks, ADR, sécurité, PRA
├─ scripts/                   # Scripts d’automatisation CLI (wrappers plan/apply, checks)
├─ .github/                   # CI/CD (workflows GitHub Actions)
└─ README.md                  # Guide de démarrage et conventions
```

---

## 1) `terraform/` – Infrastructure & déploiements pilotés IaC

### 1.1 Arborescence
```
terraform/
├─ envs/
│  ├─ dev/
│  ├─ preprod/
│  └─ prod/
├─ modules/
│  ├─ k8s-core/          # namespaces, labels, Pod Security, NetworkPolicies de base
│  ├─ ingress-nginx/     # ingress controller + params (classe, annotations communes)
│  ├─ cert-manager/      # issuers ACME DNS-01 (Cloudflare)
│  ├─ external-dns/      # gestion enregistrements DNS via CF
│  ├─ vault-eso/         # intégration ESO ←→ Vault (auth, mappings)
│  ├─ storage-hostpath/  # StorageClass/PV de test
│  ├─ longhorn/          # StorageClass Longhorn (activable par flag)
│  ├─ db-mariadb/        # StatefulSet DB + service + policies associées
│  ├─ xwiki/             # Déploiement XWiki (chart helm piloté par TF)
│  ├─ solr/              # Déploiement Solr (chart helm piloté par TF)
│  └─ observability-lite/# metrics-server, kube-state-metrics (sans Grafana)
└─ global/
   ├─ providers/         # Déclarations providers (kubernetes, helm, cloudflare, vault, s3…)
   └─ backend/           # Paramétrage backend state (S3 versionné), variables communes
```

### 1.2 Rôles & conventions
- **`envs/*`** : chaque environnement tient son propre fichier de variables (domain, flags, tailles PV, etc.).  
- **`modules/*`** : éléments réutilisables, **sans valeurs spécifiques d’environnement**.  
- **`global/*`** : définition de providers et backend TF (état stocké S3 versionné).  
- **Flags clés** (dans `envs/*` via variables.tfvars) :  
  - `enable_longhorn` (false en tests, true quand multi‑nœuds),  
  - `enable_db_backups` (false au démarrage),  
  - `db_engine`/`db_version` (par défaut MariaDB 10.11),  
  - tailles PVC (`xwiki_storage_size`, `db_storage_size`, `solr_storage_size`).

- **Nommage ressources** : `{env}-{svc}-{component}-{seq}` (ex. `dev-xwiki-app-01`).  
- **Droits/ownership** : répertoires `modules/` et `global/` = responsabilité plateforme ; `envs/*` = responsabilité équipe d’exploitation (avec PR/approbation).

---

## 2) `k8s/` – Paramétrage Helm & overlays applicatifs

### 2.1 Arborescence
```
k8s/
├─ helm-values/
│  ├─ dev/
│  │  ├─ xwiki.values.yaml
│  │  ├─ mariadb.values.yaml
│  │  ├─ solr.values.yaml
│  │  ├─ ingress-nginx.values.yaml
│  │  ├─ external-dns.values.yaml
│  │  └─ cert-manager.values.yaml
│  ├─ preprod/
│  └─ prod/
└─ overlays/              # (optionnel) patches Kustomize / YAML par env si nécessaire
```

### 2.2 Rôles & conventions
- **`helm-values/*`** : centralise les **valeurs de chart** par environnement (sans secrets).  
- Les **secrets** (DB, admin XWiki, CF token, SMTP) viennent de **Vault via ESO** → montés comme `Secret`/env K8s.  
- Les fichiers `*.values.yaml` ne contiennent **pas de secrets** ; uniquement des paramètres non sensibles (réplicas, ressources, noms de service, hostnames…).

---

## 3) `apps/` – Confs applicatives XWiki & Solr

### 3.1 Arborescence
```
apps/
├─ xwiki/
│  ├─ config/            # Paramétrage XWiki (sans secrets, ex. locales, features)
│  ├─ branding/          # Thème / logos si besoin
│  └─ docs/              # Notes d’exploitation XWiki (fonctionnel)
└─ solr/
   ├─ config/            # Schémas/collections spécifiques si besoin
   └─ docs/
```

### 3.2 Rôles & conventions
- **`apps/xwiki/config`** : options fonctionnelles/documentaires ; **les secrets restent dans Vault**.  
- **`apps/solr/config`** : schéma de recherche si customisé (sinon valeurs par défaut du chart).  
- **Équipe applicative** propriétaire de `apps/*` ; **équipe plateforme** révise les impacts infra.

---

## 4) `ansible/` – Bootstrap cluster & opérations hôte

### 4.1 Arborescence
```
ansible/
├─ inventories/          # bastion/hosts, variables group/host
├─ roles/                # rôles k8s, runtime, sécurité
├─ playbooks/
│  ├─ cluster-bootstrap.yml
│  └─ postinstall.yml
└─ docs/
```

### 4.2 Rôles & conventions
- **Cluster déjà déployé** via Ansible : ces artefacts documentent le bootstrap et servent pour maintenance hôte si nécessaire.  
- Ansible **ne déploie pas** les applis K8s ; c’est fait via Terraform/Helm.

---

## 5) `ops/` – Observabilité, sécurité, politiques K8s

### 5.1 Arborescence
```
ops/
├─ observability/
│  ├─ metrics-lite/      # metrics-server, kube-state-metrics (sans Grafana)
│  └─ synthetic/         # checks HTTP basiques (optionnels)
├─ security/
│  ├─ pss/               # Pod Security Standards (restricted)
│  ├─ network-policies/  # deny-all + règles ciblées (xwiki→db, xwiki→solr, ingress→xwiki)
│  └─ bench/             # CIS/Kube‑bench (notes, pas de secrets)
└─ ingress/
   └─ policies/          # headers sécurité, HSTS, rate‑limit login
```

### 5.2 Rôles & conventions
- **Observabilité** minimale au départ, activable en “full” plus tard (Grafana/Loki).  
- **Sécurité** : baseline commune appliquée à tous les namespaces applicatifs.  
- **Ingress** : règles transverses (headers, limites) non spécifiques à une app.

---

## 6) `docs/` – Runbooks, ADR, sécurité, PRA

### 6.1 Arborescence
```
docs/
├─ runbooks/
│  ├─ 01-bootstrap.md
│  ├─ 02-deployer-xwiki.md
│  ├─ 03-activer-longhorn.md
│  ├─ 04-activer-backups.md
│  └─ 05-rotation-secrets.md
├─ adr/                  # Architecture Decision Records (décisions formalisées)
├─ security/             # Politique d’accès, MFA, comptes break-glass
└─ pra/                  # Stratégies de sauvegarde/restauration, RTO/RPO
```

### 6.2 Conventions
- **Runbooks** concis, actionnables, ordonnés.  
- **ADR** pour tracer les choix (ex. MariaDB vs MySQL, hostPath→Longhorn, etc.).

---

## 7) `scripts/` – Outils CLI & automatisations locales
- **Wrapper Terraform** (plan/apply avec vérifs), **checks de prérequis** (kubectl, helm, context).  
- **Rotation** de secrets (invalidation/renew), **helpers** pour dump/migration PVs quand passage à Longhorn.  
- Convention : scripts idempotents, log clair, **sans secrets en dur**.

---

## 8) `.github/` – CI/CD (GitHub Actions)
- Workflows : **Lint + `terraform plan` sur PR**, **`terraform apply` sur merge** (environnement ciblé).  
- Gestion du **state** (S3 versionné) et des **permissions minimales** (OIDC/GitHub → cloud provider/CF/Vault).  
- **Protections de branche** : PR review obligatoire, tags de version pour modules.

---

## 9) Conventions de données & secrets

### 9.1 Vault (KV v2) – arbo recommandée
```
kv/
└─ xwiki/
   ├─ dev/
   │  ├─ db/
   │  │  ├─ root
   │  │  └─ app
   │  ├─ app/
   │  │  └─ admin
   │  └─ cloudflare/
   │     └─ api_token
   ├─ preprod/
   └─ prod/
```

- **ESO** : mappe ces chemins vers des `Secret` K8s dans les **namespaces dédiés** (`db`, `xwiki`, etc.).  
- Rotation gérée côté Vault (ESO resynchronise automatiquement).

### 9.2 Nommage namespaces & ressources
- Namespaces : `xwiki`, `db`, `solr`, `ingress`, `cert-manager`, `external-dns`, `vault`, `observability`.  
- Services/Ingress : `xwiki.nudger.logo-solutions.fr` en **TLS only**, HSTS.  
- Labels obligatoires sur **toutes** les ressources : `owner`, `env`, `costcenter`, `data_class`, `compliance`.

---

## 10) Flux d’évolution (tests → multi‑nœuds → prod)

1. **Phase Tests (actuelle)** : hostPath, DB StatefulSet, observabilité légère, logs locaux.  
2. **Activation Longhorn** (flag Terraform) dès 2+ nœuds → migration PVC (rsync/Velero).  
3. **Backups DB & Velero** (flag Terraform) → politique de rétention + tests de restauration.  
4. **Durcissement** progressif (NetworkPolicies complètes, OIDC SSO, rate‑limit login).  
5. **Montée de SLA** : DB en VM dédiée ou Galera si besoin, ingress via LB/MetalLB (ou CF→NodePort conservé).

---

## 11) Gouvernance & responsabilités

- **Plateforme** : `terraform/modules`, `ops/*`, intégrations Vault/ESO, sécurité transversale.  
- **Applicatif** : `apps/*`, `k8s/helm-values/*` (paramètres fonctionnels).  
- **Exploitation** : `terraform/envs/*`, `docs/runbooks/*`, supervision quotidienne.  
- **Contrôle des changements** : PR + review ; versionnage des modules, ADR pour décisions majeures.

---

## 12) Checklist de conformité interne (extraits)

- Aucune donnée secrète committée (scan PR).  
- TLS by default, HSTS, headers sécurité.  
- NetworkPolicies par défaut **deny‑all**.  
- Secrets via Vault/ESO seulement.  
- State Terraform versionné (S3) + approbation PR obligatoire.  
- Runbooks à jour : bootstrap, Longhorn, Backups, Restore, Rotation secrets.
