#!/usr/bin/env bash
set -euo pipefail
export ARC_APP_NAME="arc-logo-org"
export ARC_APP_ID="2210922"
export ARC_APP_INSTALLATION_ID="92410983"
export ARC_PRIVATE_KEY_PATH="/etc/arc/${ARC_APP_NAME}.private-key.pem"
export ARC_ENV_PATH="/etc/arc/arc_env.sh"

# --- Bitwarden items
# (⚠️ ces noms doivent correspondre EXACTEMENT à ce que tu as dans ton coffre Bitwarden)
export ARC_BITWARDEN_ITEM_KEY="arc-logo-org-private-key"
export ARC_BITWARDEN_ITEM_ID="arc-logo-org-app-id"
export ARC_BITWARDEN_ITEM_INSTALL="arc-logo-org-install-id"

C_RESET="\033[0m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"
C_YELLOW="\033[1;33m"

log()   { echo -e "${C_BLUE}🔹 $*${C_RESET}"; }
ok()    { echo -e "${C_GREEN}✅ $*${C_RESET}"; }
warn()  { echo -e "${C_YELLOW}⚠️  $*${C_RESET}"; }
error() { echo -e "${C_RED}❌ $*${C_RESET}" >&2; exit 1; }

check_bw() {
  bw status | grep -q '"unlocked"' || error "Vault Bitwarden verrouillé. Exécute : export BW_SESSION=\$(bw unlock --raw)"
}
check_bw
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
TF_VAR_github_app_private_key=$(bw get item "$ARC_BITWARDEN_ITEM_KEY" --session "$BW_SESSION" | jq -r '.notes')
TF_VAR_github_app_id=$(bw get item "$ARC_BITWARDEN_ITEM_ID" --session "$BW_SESSION" | jq -r '.login.username')
TF_VAR_github_app_installation_id=$(bw get item "$ARC_BITWARDEN_ITEM_INSTALL" --session "$BW_SESSION" | jq -r '.login.username')

# Génération du fichier d’environnement
cat > "$ARC_ENV_PATH" <<EOF
#!/usr/bin/env bash
export TF_VAR_github_app_private_key="$TF_VAR_github_app_private_key"
export TF_VAR_github_app_id="$TF_VAR_github_app_id"
export TF_VAR_github_app_installation_id="$TF_VAR_github_app_installation_id"
export ARC_APP_NAME="arc-logo-org"
export ARC_APP_ID="2210922"
export ARC_APP_INSTALLATION_ID="92410983"
export ARC_PRIVATE_KEY_PATH="/etc/arc/${ARC_APP_NAME}.private-key.pem"
export TF_VAR_github_repo_url="https://github.com/logo-solutions/nudger-infra"

EOF
chmod +x $ARC_ENV_PATH

ok "✅ Fichier d'environnement généré : $ARC_ENV_PATH"
