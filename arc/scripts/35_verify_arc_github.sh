#!/usr/bin/env bash
set -euo pipefail

source /etc/arc/arc_env.sh

REPO="logo-solutions/nudger-infra"
INSTALL_URL="https://github.com/settings/installations/$ARC_INSTALLATION_ID"
RUNNERS_API="https://api.github.com/repos/$REPO/actions/runners"

echo "=============================="
echo "🔎 Vérification GitHub / ARC"
echo "=============================="

command -v jq >/dev/null 2>&1 || { echo "❌ jq manquant. Installe-le avant de continuer."; exit 1; }

echo "📦 App ID : $ARC_ID"
echo "🔧 Installation ID : $ARC_INSTALLATION_ID"
echo "🌍 Dépôt cible : $REPO"
echo

[[ -f "$ARC_PRIVATE_KEY" ]] || { echo "❌ Clé privée introuvable : $ARC_PRIVATE_KEY"; exit 1; }
echo "✅ Clé privée trouvée."

echo "🔑 Génération du JWT..."
now=$(date +%s)
exp=$((now + 540))
header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -A | tr '+/' '-_' | tr -d '=')
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$now" "$exp" "$ARC_ID" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
unsigned_token="${header}.${payload}"
signature=$(printf '%s' "$unsigned_token" | openssl dgst -sha256 -sign "$ARC_PRIVATE_KEY" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT="${unsigned_token}.${signature}"
echo "✅ JWT généré."

echo "🔗 Obtention du token GitHub App..."
ACCESS_TOKEN=$(curl -s --http1.1 -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$ARC_INSTALLATION_ID/access_tokens" | jq -r '.token')

[[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]] && { echo "❌ Impossible d'obtenir le token GitHub."; exit 1; }
echo "✅ Token GitHub obtenu."

echo "🔍 Récupération des runners GitHub..."
RUNNERS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" "$RUNNERS_API")
RUNNERS_COUNT=$(echo "$RUNNERS_JSON" | jq '.total_count')

echo "📈 Nombre de runners : $RUNNERS_COUNT"
if [[ "$RUNNERS_COUNT" -gt 0 ]]; then
  echo "✅ Runners détectés :"
  echo "$RUNNERS_JSON" | jq -r '.runners[] | "\(.name)\t\(.status)"'
else
  echo "⚠️ Aucun runner trouvé dans GitHub."
  echo "   Vérifie l’installation : $INSTALL_URL"
fi

echo
echo "🧾 Résumé :"
if [[ "$RUNNERS_COUNT" -gt 0 ]]; then
  echo "✅ ARC ↔ GitHub opérationnel."
else
  echo "⚠️ ARC installé mais aucun runner enregistré côté GitHub."
fi
