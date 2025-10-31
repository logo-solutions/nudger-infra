#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../arc.env"
source "$(dirname "$0")/arc_common.sh"

log "🚀 Installation ARC v$ARC_VERSION"

kubectl create namespace "$ARC_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log "🔐 Création du secret GitHub..."
kubectl delete secret github-app-secret -n "$ARC_NAMESPACE" --ignore-not-found
kubectl create secret generic github-app-secret \
  -n "$ARC_NAMESPACE" \
  --from-literal=github_app_id="$ARC_APP_ID" \
  --from-literal=github_app_installation_id="$ARC_APP_INSTALLATION_ID" \
  --from-file=github_app_private_key="$ARC_PRIVATE_KEY_PATH"

log "📦 Déploiement du contrôleur..."
helm upgrade --install arc \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
  --namespace "$ARC_NAMESPACE" \
  --version "$ARC_VERSION" \
  --create-namespace \
  --wait

log "⚙️ Déploiement du runner..."
helm upgrade --install nudger-runner \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  --namespace "$ARC_NAMESPACE" \
  --version "$ARC_VERSION" \
  --set githubConfigUrl="$ARC_REPO_URL" \
  --set githubConfigSecret=github-app-secret \
  --set runnerScaleSetName=nudger-autoscaling-set \
  --set minRunners=1 \
  --set maxRunners=2 \
  --set controllerServiceAccount.name=arc-gha-rs-controller \
  --wait

ok "Installation complète effectuée."
