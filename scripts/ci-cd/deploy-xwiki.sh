#!/usr/bin/env bash
# scripts/deploy-xwiki.sh
set -euo pipefail

# --------------------------------------------
# 🧩 Variables
# --------------------------------------------
ENVIRONMENT="${1:-}"
IMAGE_TAG="${2:-}"

BASE_DIR="$HOME/nudger-infra"
MANIFEST_PATH="$BASE_DIR/manifests/xwiki/overlays/$ENVIRONMENT"

# Couleurs
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

# --------------------------------------------
# 🧱 Fonctions
# --------------------------------------------

log() { echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $*"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; exit 1; }

# --------------------------------------------
# 🧮 Validation
# --------------------------------------------
if [[ -z "$ENVIRONMENT" ]]; then
  error "Usage: $0 [integration|recette] [optional: image-tag]"
fi

if [[ ! -d "$MANIFEST_PATH" ]]; then
  error "Overlay non trouvé : $MANIFEST_PATH"
fi

log "🚀 Déploiement XWiki sur environnement: ${ENVIRONMENT}"

# --------------------------------------------
# 🧩 (Optionnel) Mise à jour de l’image
# --------------------------------------------
if [[ -n "$IMAGE_TAG" ]]; then
  log "🔧 Mise à jour du tag d'image vers ${IMAGE_TAG}"
  yq e ".image.tag = \"${IMAGE_TAG}\"" -i "${MANIFEST_PATH}/values.yaml"
fi

# --------------------------------------------
# ⚙️ Déploiement avec Kustomize
# --------------------------------------------
log "📦 Application du manifest via Kustomize..."
kubectl apply -k "$MANIFEST_PATH"

# --------------------------------------------
# 🧪 Vérification du déploiement
# --------------------------------------------
NAMESPACE="$ENVIRONMENT"

log "⏳ Attente du déploiement complet..."
kubectl -n "$NAMESPACE" rollout status deployment/xwiki --timeout=300s || {
  error "Le déploiement a échoué dans $NAMESPACE"
}

kubectl -n "$NAMESPACE" get pods

success "Déploiement XWiki réussi sur $ENVIRONMENT 🎉"
