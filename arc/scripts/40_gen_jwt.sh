#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../arc.env"
source "$(dirname "$0")/arc_common.sh"

log "🔑 Génération du JWT..."

now=$(date +%s)
exp=$((now + 540))

header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -A | tr '+/' '-_' | tr -d '=')
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$now" "$exp" "$ARC_APP_ID" | openssl base64 -A | tr '+/' '-_' | tr -d '=')

unsigned_token="${header}.${payload}"

signature=$(printf '%s' "$unsigned_token" | openssl dgst -sha256 -sign "$ARC_PRIVATE_KEY_PATH" | openssl base64 -A | tr '+/' '-_' | tr -d '=')

JWT="${unsigned_token}.${signature}"

echo "$JWT"
