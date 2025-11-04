# 🧾 ADR007 – Sécurité et durcissement Kubernetes

**Date :** 2025-09-26  
**Statut :** 🟢 Adopté (en cours de déploiement)

---

## 🎯 Contexte

Le cluster Kubernetes doit être sécurisé contre les déploiements non conformes et garantir la cohérence des workloads entre les environnements.  
Deux mécanismes principaux sont utilisés pour atteindre cet objectif :

- **Pod Security Admission (PSA)** : mécanisme natif de sécurité Kubernetes.
- **Kyverno** : moteur de politiques de validation et de conformité.

---

## ⚙️ Analyse des solutions

### 🧱 Pod Security Admission (PSA)

**Avantages :**
- ✅ Mécanisme **intégré nativement** à Kubernetes (aucune dépendance externe).
- ✅ Applique des **profils standardisés** (Privileged, Baseline, Restricted).  
- ✅ Simplicité d’activation : configuration par **labels de namespace**.  
- ✅ Peu de maintenance, parfait pour un durcissement initial.  

**Inconvénients :**
- ❌ Peu flexible (règles globales, non personnalisables finement).  
- ❌ Ne couvre pas les bonnes pratiques organisationnelles (labels, ressources, conventions).  
- ❌ Ne permet pas d’auto-remédiation ni de génération automatique de ressources.  

### 🧩 Kyverno (policies de validation)

**Avantages :**
- ✅ Très **flexible et déclaratif** (policies YAML).  
- ✅ Permet des **règles personnalisées** : interdire `:latest`, imposer des labels, vérifier les `resource limits`, etc.  
- ✅ Compatible avec GitOps (ArgoCD, FluxCD) et CI/CD.  
- ✅ Peut **corriger ou générer** des ressources automatiquement (auto-remédiation).  
- ✅ Fournit une **auditabilité** et un contrôle de conformité dans le temps.  

**Inconvénients :**
- ❌ Ajoute une **couche de complexité** (CRDs, Webhooks).  
- ❌ Peut bloquer des déploiements si les manifests ne respectent pas les règles.  
- ❌ Requiert une maintenance et une validation des policies au fil du temps.  

---

## 🧭 Décision

Nous adoptons une approche **hybride et progressive** :

| Composant | Décision |
|------------|-----------|
| **PSA** | Activation par défaut du profil **Baseline** sur tous les namespaces. |
| **Kyverno** | Déploiement d’un ensemble de **règles complémentaires** (validation, auto-remédiation). |
| **Cert-manager** | Conservation pour la **gestion TLS automatique (Let's Encrypt)**. |

---

## 🧩 Application par environnement

### 🔹 Namespace **intégration**
- Objectif : permettre les tests et itérations rapides.  
- **PSA :** profil *Baseline* (bloque les comportements dangereux mais autorise un certain niveau de liberté).  
- **Kyverno :** mode *audit* (les violations sont signalées mais non bloquantes).  
- **Particularités :** autorisation temporaire d’images `:latest` et de volumes hostPath pour les tests rapides.  

### 🔹 Namespace **recette**
- Objectif : validation fonctionnelle avant la mise en production.  
- **PSA :** profil *Baseline*.  
- **Kyverno :** mode *enforce* pour les règles critiques (ex. : interdiction de `:latest`, labels obligatoires).  
- **Particularités :** contrôle strict sur les labels, images signées, et ressources (CPU/mémoire).  

### 🔹 Namespace **production**
- Objectif : fiabilité, conformité et sécurité maximale.  
- **PSA :** profil *Restricted*.  
- **Kyverno :** mode *enforce* complet, incluant les policies de conformité et d’audit.  
- **Particularités :**
  - Interdiction des privilèges élevés (`securityContext.privileged`).  
  - Validation stricte des `resource limits` et des labels de conformité.  
  - Vérification des secrets utilisés et des images issues de registres approuvés.  

---

## 🧩 Conséquences

### ✅ Avantages
- Sécurité renforcée et adaptée à chaque environnement.  
- Standardisation progressive de la conformité (dev → recette → prod).  
- Meilleure visibilité sur les risques et les non-conformités.  

### ⚠️ Inconvénients
- Besoin d’adaptation initiale des manifests existants (notamment en recette et prod).  
- Risque de blocage lors des déploiements non conformes en mode *enforce*.  
- Nécessite une surveillance continue des logs Kyverno et des alertes PSA.  

---

## 🔒 Conclusion

Cette approche hybride PSA + Kyverno permet d’assurer :  
- une **base de sécurité robuste** via PSA,  
- une **personnalisation fine et auditable** via Kyverno,  
- et une **progressivité** selon l’environnement (intégration permissif, production stricte).

Le déploiement suivra une montée en maturité :  
d’abord PSA Baseline sur tous les namespaces, puis ajout progressif des policies Kyverno en mode *audit*, avant passage en *enforce*.

---

