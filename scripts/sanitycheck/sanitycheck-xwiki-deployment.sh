#!/usr/bin/env bash
set -euo pipefail

echo "🧠 Sanity Check - XWiki Kubernetes Terraform Deployment"
echo "------------------------------------------------------"

# Initialise un compteur d’erreurs

## 1. Terraform
echo "🔍 [1/10] Vérification de Terraform..."
if command -v terraform >/dev/null 2>&1; then
  terraform version | head -n 1
else
  echo "❌ Terraform non installé"
fi

## 2. Kubectl
echo "🔍 [2/10] Vérification de kubectl et du contexte actif..."
if command -v kubectl >/dev/null 2>&1; then
  kubectl version  --client
  if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Cluster Kubernetes inaccessible"
  fi
else
  echo "❌ kubectl non installé"
fi

## 3. Helm
echo "🔍 [3/10] Vérification de Helm..."
if command -v helm >/dev/null 2>&1; then
  helm version --short
else
  echo "❌ Helm non installé"
fi

## 4. Variables d’env attendues
echo "🔍 [4/10] Vérification des secrets d’API (Cloudflare, etc.)..."
for var in CLOUDFLARE_API_TOKEN CLOUDFLARE_EMAIL HCLOUD_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Variable $var non définie"
  else
    echo "✅ $var défini"
  fi
done

## 5. Modules Terraform
echo "🔍 [5/10] Vérification des modules Terraform déclarés..."
grep -E 'source\s+=' *.tf | grep -v '^#' || echo "ℹ️ Aucun module Terraform détecté"

## 6. Terraform init
echo "🔍 [6/10] Vérification de l’état de Terraform (init)..."
if [[ -f "./.terraform.lock.hcl" && -d ".terraform" ]]; then
  echo "✅ Terraform init détecté"
else
  echo "⚠️  Lancement requis : terraform init"
fi

## 7. Permissions Kubernetes
echo "🔍 [7/10] Vérification des permissions K8s..."
for action in "create namespace" "create clusterrolebinding" "create issuer.cert-manager.io" "create ingress"; do
  if kubectl auth can-i $action >/dev/null 2>&1; then
    echo "✅ Can $action"
  else
    echo "❌ Cannot $action"
  fi
done

## 8. CRDs attendues
echo "🔍 [8/10] Vérification des CRDs cert-manager / external-dns..."
for crd in certificates.cert-manager.io clusterissuers.cert-manager.io dnsrecords.externaldns.k8s.io; do
  if kubectl get crd "$crd" >/dev/null 2>&1; then
    echo "✅ CRD $crd présente"
  else
    echo "⚠️ CRD $crd absente"
  fi
done

## 9. Providers Terraform
echo "🔍 [9/10] Vérification des providers déclarés..."
grep 'provider "' *.tf || echo "⚠️ Aucun provider détecté"

## 10. Nœuds K8s
echo "🔍 [10/10] Vérification des nœuds Kubernetes..."
kubectl get nodes -o wide || { echo "❌ Aucun nœud détecté"}

echo "------------------------------------------------------"
