#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../arc.env"
source "$(dirname "$0")/arc_common.sh"

log "🧹 Désinstallation complète d'ARC ($ARC_NAMESPACE)..."

for kind in autoscalingrunnerset ephemeralrunnerset ephemeralrunner autoscalinglistener; do
  kubectl delete "$kind" -n "$ARC_NAMESPACE" --all --ignore-not-found
done

for rel in nudger-runner arc actions-runner-controller; do
  helm uninstall "$rel" -n "$ARC_NAMESPACE" || true
done

kubectl delete crd -l app.kubernetes.io/part-of=gha-rs-controller --ignore-not-found || true
kubectl delete secret -n "$ARC_NAMESPACE" --all --ignore-not-found
kubectl delete configmap -n "$ARC_NAMESPACE" --all --ignore-not-found
kubectl delete all -n "$ARC_NAMESPACE" --all --ignore-not-found
kubectl delete namespace "$ARC_NAMESPACE" --ignore-not-found || true

ok "Cluster nettoyé."
