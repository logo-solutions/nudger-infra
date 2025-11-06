#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="infra_snapshot_$(date +%Y%m%d_%H%M%S)"
export OUTPUT_DIR   # <-- correction essentielle
mkdir -p "$OUTPUT_DIR"

echo "📦 Collecte des fichiers de configuration (sans la documentation)"
echo "📁 Dossier de sortie : $OUTPUT_DIR"
echo

copy_files() {
  local section="$1"
  shift
  echo "➡️  $section"
  for pattern in "$@"; do
    find . -type f -path "$pattern" -exec bash -c '
      for f; do
        dest="$OUTPUT_DIR/$f"
        mkdir -p "$(dirname "$dest")"
        echo "  • $f"
        cat "$f" > "$dest"
      done
    ' bash {} +
  done
  echo
}

# --- Terraform ---
copy_files "Terraform" \
  "./terraform/*.tf" \
  "./terraform/**/*.tf" \
  "./terraform/**/*.tfvars" \
  "./terraform/**/*.lock.hcl" \
  "./terraform/**/*.yaml"

# --- Manifests Kubernetes ---
copy_files "Manifests Kubernetes" \
  "./manifests/**/*.yaml" \
  "./manifests/**/*.yml" \
  "./manifests/**/*.sql" \
  "./manifests/**/*.sh"

# --- ARC GitHub Runner ---
copy_files "ARC GitHub Runner" \
  "./arc/**/*.env" \
  "./arc/**/*.sh" \
  "./arc/**/*.ms"

# --- CI/CD GitHub Workflows ---
copy_files "CI/CD GitHub Workflows" \
  "./.github/workflows/**/*.yml" \
  "./.github/workflows/**/*.yaml"

echo "✅ Collecte terminée"
echo "Tous les fichiers copiés dans : $OUTPUT_DIR"
echo
echo "👉 Vous pouvez ensuite générer un zip :"
echo "zip -r ${OUTPUT_DIR}.zip $OUTPUT_DIR"
