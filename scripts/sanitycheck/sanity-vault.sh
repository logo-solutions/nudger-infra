#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# Vault sanity check script – Kubernetes + Ingress validation
# Author: Loïc Bourmelon (logo-solutions)
# ────────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="vault"
INGRESS_HOST="vault.nudger.logo-solutions.fr"
VAULT_PORT=8200

echo "🔍 [1/7] Vérification du namespace..."
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || {
  echo "❌ Namespace '$NAMESPACE' inexistant"
  exit 1
}
echo "✅ Namespace OK"

echo "🔍 [2/7] Vérification des pods..."
PODS_OK=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -c 'Running' || true)
if [[ "$PODS_OK" -lt 2 ]]; then
  echo "❌ Certains pods ne sont pas Running :"
  kubectl get pods -n "$NAMESPACE"
  exit 1
fi
echo "✅ Pods OK"

echo "🔍 [3/7] Vérification des services..."
kubectl get svc -n "$NAMESPACE" | grep -q vault || {
  echo "❌ Aucun service Vault trouvé"
  exit 1
}
echo "✅ Services OK"

echo "🔍 [4/7] Test du port interne (ClusterIP)..."
POD=$(kubectl get pod -n "$NAMESPACE" -l "app.kubernetes.io/name=vault" -o name | head -n1)
kubectl exec -n "$NAMESPACE" "$POD" -- sh -c "wget -qO- --timeout=2 http://127.0.0.1:${VAULT_PORT}/v1/sys/health >/dev/null && echo 200" 2>/dev/null \
  | grep -q 200 && echo '✅ Port interne répond' || echo '⚠️  Port interne ne répond pas'
echo "🔍 [5/7] Vérification de l’Ingress..."
if kubectl get ingress -n "$NAMESPACE" vault >/dev/null 2>&1; then
  echo "✅ Ingress détecté"
  kubectl get ingress -n "$NAMESPACE" vault
else
  echo "⚠️  Aucun Ingress Vault trouvé"
fi

echo "🔍 [6/7] Vérification du certificat TLS..."
kubectl get secret -n "$NAMESPACE" vault-tls >/dev/null 2>&1 \
  && echo "✅ Secret TLS 'vault-tls' trouvé" \
  || echo "⚠️  Secret TLS 'vault-tls' manquant"

echo "🔍 [7/7] Test d’accessibilité externe via Ingress..."
curl -sk -o /dev/null -w "%{http_code}\n" "https://${INGRESS_HOST}/v1/sys/health" | grep -Eq '200|503' \
  && echo "✅ Vault accessible via Ingress HTTPS" \
  || echo "❌ Vault injoignable via HTTPS"

echo ""
echo "🟩 Sanity check terminé."
