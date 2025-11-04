#!/usr/bin/env bash
set -euo pipefail

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
