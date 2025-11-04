#!/usr/bin/env bash
set -euo pipefail

echo "=============================="
echo "🧩 Vérification complète ARC (K8s + GitHub)"
echo "=============================="

./scripts/31_verify_arc_k8s.sh
echo
./scripts/35_verify_arc_github.sh

echo
echo "🎯 Vérification complète terminée."
