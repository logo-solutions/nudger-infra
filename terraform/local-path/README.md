# Terraform Module – Local Path Provisioner

Ce module Terraform déploie le **provisioner `local-path-provisioner`** de Rancher
via le chart Helm officiel maintenu par **Containeroo**  
👉 [https://charts.containeroo.ch](https://charts.containeroo.ch)

---

## 🧩 Prérequis

- Cluster Kubernetes opérationnel (`kubectl get nodes` OK)
- Helm 3 et Terraform >= 1.6 installés
- Providers :
  - `hashicorp/kubernetes >= 2.29`
  - `hashicorp/helm >= 2.12`

---

## 🧱 Initialisation manuelle du dépôt Helm (facultatif)

Même si Terraform gère automatiquement les dépôts Helm,
il est recommandé de **pré-enregistrer le dépôt** en environnement CI/CD :

```bash
helm repo add containeroo https://charts.containeroo.ch
helm repo update
helm search repo containeroo/local-path-provisioner
