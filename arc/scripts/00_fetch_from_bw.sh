#!/usr/bin/env bash
set -exuo pipefail
source "$(dirname "$0")/../arc.env"
source "$(dirname "$0")/arc_common.sh"

check_bw
mkdir -p /etc/arc

log "📦 Récupération des secrets GitHub App depuis Bitwarden..."

# Vérification de la session Bitwarden
if [[ -z "${BW_SESSION:-}" ]]; then
  log "🔐 Bitwarden verrouillé — déverrouillage en cours..."
  export BW_SESSION=$(bw unlock --raw)
  ok "Bitwarden déverrouillé."
else
  log "🔓 Session Bitwarden déjà active."
fi

# Synchronisation du coffre (utile en CI/CD)
bw sync --session "$BW_SESSION" >/dev/null 2>&1 || true

# Récupération des secrets
PRIVATE_KEY=$(bw get item "$ARC_BITWARDEN_ITEM_KEY" --session "$BW_SESSION" | jq -r '.notes')
APP_ID=$(bw get item "$ARC_BITWARDEN_ITEM_ID" --session "$BW_SESSION" | jq -r '.login.username')
INSTALL_ID=$(bw get item "$ARC_BITWARDEN_ITEM_INSTALL" --session "$BW_SESSION" | jq -r '.login.username')

# Écriture sécurisée de la clé privée
echo "$PRIVATE_KEY" > "$ARC_PRIVATE_KEY_PATH"
chmod 600 "$ARC_PRIVATE_KEY_PATH"
ok "✅ Clé privée écrite dans $ARC_PRIVATE_KEY_PATH"

# Génération du fichier d’environnement
cat > "$ARC_ENV_PATH" <<EOF
#!/usr/bin/env bash
export ARC_ID="$APP_ID"
export ARC_INSTALLATION_ID="$INSTALL_ID"
export ARC_PRIVATE_KEY="$ARC_PRIVATE_KEY_PATH"
EOF

chmod 600 "$ARC_ENV_PATH"
ok "✅ Fichier d'environnement généré : $ARC_ENV_PATH"
