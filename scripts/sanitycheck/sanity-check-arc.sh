#!/bin/bash

set -euo pipefail

# Namespace où ARC est installé
NAMESPACE="actions-runner-system"

echo "🔍 [SANITY CHECK] Vérification de l'état d'Actions Runner Controller (ARC) dans le namespace: $NAMESPACE"
echo "──────────────────────────────────────────────────────────────"

# 1️⃣ Vérifier si le namespace existe
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "❌ Namespace $NAMESPACE introuvable"
  exit 1
fi
echo "✅ Namespace $NAMESPACE trouvé"

# 2️⃣ Vérifier les pods ARC
echo -e "\n📦 Vérification des Pods dans $NAMESPACE..."
kubectl get pods -n "$NAMESPACE" -o wide

# Vérifier que tous les pods sont en état Running
PODS_STATUS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running -o custom-columns=":metadata.name,:status.phase")

# Enlever les lignes vides ou espaces excédentaires
PODS_STATUS=$(echo "$PODS_STATUS" | sed '/^[[:space:]]*$/d')

# Vérification si la variable est vide
if [[ -n "$PODS_STATUS" ]]; then
  echo "⚠️ Le(s) pod(s) suivant(s) ne sont pas en état Running :"
  echo "$PODS_STATUS"
  exit 1
fi
echo "✅ Tous les pods sont en état Running"

# 3️⃣ Vérifier les CRDs
echo -e "\n📝 Vérification des CRDs nécessaires..."
CRDS=$(kubectl get crds | grep "actions.summerwind.dev")
if [[ -z "$CRDS" ]]; then
  echo "❌ Les CRDs nécessaires pour ARC ne sont pas installées"
  exit 1
fi
echo "✅ CRDs installées :"
echo "$CRDS"

# 4️⃣ Vérifier les secrets
echo -e "\n🔐 Vérification des secrets..."
kubectl get secrets -n "$NAMESPACE"

# Vérifier que les secrets requis sont présents
SECRET_GITHUB_TOKEN=$(kubectl get secret controller-manager -n "$NAMESPACE" --ignore-not-found)
SECRET_CERT=$(kubectl get secret actions-runner-controller-serving-cert -n "$NAMESPACE" --ignore-not-found)

if [[ -z "$SECRET_GITHUB_TOKEN" ]] || [[ -z "$SECRET_CERT" ]]; then
  echo "❌ Un ou plusieurs secrets requis manquent"
  exit 1
fi
echo "✅ Secrets nécessaires trouvés"

# 5️⃣ Vérifier les RunnerDeployments
echo -e "\n📜 Vérification des RunnerDeployments..."
RUNNER_DEPLOYMENTS=$(kubectl get runnerdeployments.actions.summerwind.dev -n "$NAMESPACE")
if [[ -z "$RUNNER_DEPLOYMENTS" ]]; then
  echo "❌ Aucun RunnerDeployment trouvé"
  exit 1
fi
echo "✅ RunnerDeployments trouvés :"
echo "$RUNNER_DEPLOYMENTS"

# 6️⃣ Vérifier les logs du contrôleur ARC
echo -e "\n📝 Vérification des logs du contrôleur ARC..."
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=actions-runner-controller -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n "$NAMESPACE" "$POD_NAME"

# 7️⃣ Vérifier l'état des runners dans GitHub
echo -e "\n🌍 Vérification de l'état des runners dans GitHub..."
RUNNERS_STATUS=$(kubectl get runners.actions.summerwind.dev -n "$NAMESPACE")
if [[ -z "$RUNNERS_STATUS" ]]; then
  echo "❌ Aucun runner trouvé dans GitHub"
  exit 1
fi
echo "✅ Runners trouvés dans GitHub :"
echo "$RUNNERS_STATUS"

echo "──────────────────────────────────────────────────────────────"
echo "✅ Sanity check terminé. L'environnement GitHub Actions Runner semble fonctionner correctement."
