#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/var/log/arc"
LOG_FILE="$LOG_DIR/health.log"
NS="arc"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

source /etc/arc/arc_env.sh

REPO="logo-solutions/nudger-infra"
RUNNERS_API="https://api.github.com/repos/$REPO/actions/runners"

# --- Logging helper
log() { echo -e "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "====================  HEALTHCHECK ARC ($DATE)  ===================="

# --- Vérification Kubernetes
log "📦 Vérification Kubernetes..."
if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  log "❌ Namespace '$NS' introuvable."
  exit 1
fi

# Contrôleur
CTRL_READY=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=gha-rs-controller \
  -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")

# Runner
RUNNER_READY=$(kubectl get pods -n "$NS" \
  -l 'actions-ephemeral-runner=True' \
  -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
if [[ "$CTRL_READY" == "true" ]]; then
  log "✅ Controller ARC : OK"
else
  log "❌ Controller ARC non prêt"
fi

if [[ "$RUNNER_READY" == "true" ]]; then
  log "✅ Runner ARC : OK"
else
  log "❌ Aucun runner actif (pod non prêt)"
fi

# --- Génération du JWT
log "🔑 Génération du JWT..."
now=$(date +%s)
exp=$((now + 540))
header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -A | tr '+/' '-_' | tr -d '=')
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$now" "$exp" "$ARC_ID" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
unsigned="${header}.${payload}"
sig=$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$ARC_PRIVATE_KEY" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT="${unsigned}.${sig}"

# --- Test GitHub App
log "🌍 Vérification GitHub App / API..."
ACCESS_TOKEN=$(curl -s --http1.1 -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$ARC_INSTALLATION_ID/access_tokens" | jq -r '.token' || true)

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  log "❌ Erreur : impossible d’obtenir le token GitHub."
  exit 2
fi
log "✅ Token GitHub obtenu."

# --- Vérif des runners GitHub
RUNNERS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" "$RUNNERS_API")
RUNNERS_COUNT=$(echo "$RUNNERS_JSON" | jq '.total_count')
RUNNERS_ONLINE=$(echo "$RUNNERS_JSON" | jq '[.runners[] | select(.status=="online")] | length')

log "📊 Runners GitHub : total=$RUNNERS_COUNT | online=$RUNNERS_ONLINE"

if [[ "$RUNNERS_ONLINE" -gt 0 ]]; then
  log "✅ ARC ↔ GitHub opérationnel ($RUNNERS_ONLINE runner(s) en ligne)"
  STATUS="OK"
else
  log "⚠️ Aucun runner GitHub en ligne."
  STATUS="WARN"
fi

log "=================================================================="
echo

# --- Sortie clean
[[ "$STATUS" == "OK" ]] && exit 0 || exit 3
