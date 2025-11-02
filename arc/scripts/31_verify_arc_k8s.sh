#!/usr/bin/env bash
set -euo pipefail

NS="arc"

echo "=============================="
echo "📊 Vérification Kubernetes - namespace '$NS'"
echo "=============================="

if ! kubectl get ns "$NS" &>/dev/null; then
  echo "❌ Namespace '$NS' introuvable."
  exit 1
fi

echo "🔹 Pods ARC :"
kubectl get pods -n "$NS" -o wide || true

echo
echo "🔹 AutoscalingRunnerSets :"
kubectl get autoscalingrunnersets -n "$NS" || true

echo
echo "🔹 Logs du controller (extrait 20 dernières lignes) :"
kubectl logs -n "$NS" -l app.kubernetes.io/name=gha-rs-controller --tail=20 || true

echo
echo "✅ Vérification Kubernetes terminée."
