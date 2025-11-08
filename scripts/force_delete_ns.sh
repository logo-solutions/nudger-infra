#!/usr/bin/env bash
set -euo pipefail
NS="${1:-tnamespace_a_supprimer}"
echo "🚨 Suppression forcée du namespace: $NS"

# Supprimer toutes les ressources
kubectl api-resources --verbs=list --namespaced -o name | \
xargs -n 1 kubectl delete --all -n "$NS" --force --grace-period=0 --ignore-not-found || true

# Supprimer le namespace
kubectl delete ns "$NS" --grace-period=0 --force --ignore-not-found || true

# Supprimer les finalizers via API
if kubectl get ns "$NS" 2>/dev/null | grep -q Terminating; then
  echo "🧨 Suppression finale via API proxy..."
  kubectl get ns "$NS" -o json | jq '.spec.finalizers=[]' > /tmp/$NS.json
  kubectl proxy --port=8001 &
  sleep 2
  curl -k -H "Content-Type: application/json" -X PUT \
    --data-binary @/tmp/$NS.json \
    http://127.0.0.1:8001/api/v1/namespaces/$NS/finalize
fi

echo "✅ Namespace $NS supprimé (force)"
