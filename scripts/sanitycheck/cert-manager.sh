#!/usr/bin/env bash
set -euo pipefail

NS="cert-manager"
echo -e "\n🔒 Vérification de Cert-Manager dans le namespace: ${NS}"
echo "──────────────────────────────────────────────────────────────"

# 1️⃣ Vérification des namespaces
echo -e "\n📦 Vérification du namespace $NS..."
if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "❌ Namespace $NS introuvable"
  exit 1
fi
echo "✅ Namespace $NS présent"

# 2️⃣ Vérification des pods Cert-Manager
echo -e "\n📦 Vérification des pods Cert-Manager..."
kubectl get pods -n "$NS"

# Vérifier que les pods Cert-Manager sont en état 'Running'
for pod in $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].metadata.name}'); do
  status=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.status.phase}')
  if [[ "$status" != "Running" ]]; then
    echo "⚠️ Pod $pod n'est pas en état 'Running' (état: $status)"
  else
    echo "✅ Pod $pod opérationnel (état: $status)"
  fi
done

# 3️⃣ Vérification des CRDs Cert-Manager
echo -e "\n📝 Vérification des CRDs Cert-Manager..."
kubectl get crds | grep cert-manager

# Vérifier que les CRDs de Cert-Manager sont installées
if ! kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
  echo "❌ CRD 'clusterissuers.cert-manager.io' introuvable"
  exit 1
fi
if ! kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; then
  echo "❌ CRD 'certificates.cert-manager.io' introuvable"
  exit 1
fi
echo "✅ CRDs Cert-Manager installées"

# 4️⃣ Vérification des ClusterIssuer
echo -e "\n📝 Vérification des ClusterIssuers..."
kubectl get clusterissuer -n "$NS"

# 5️⃣ Vérification des Certificates
echo -e "\n📄 Vérification des Certificates créés par Cert-Manager..."
kubectl get certificates -n "$NS"

# Vérifier que les certificats sont en statut 'Ready' ou 'Issued'
for cert in $(kubectl get certificates -n "$NS" -o jsonpath='{.items[*].metadata.name}'); do
  status=$(kubectl get certificate "$cert" -n "$NS" -o jsonpath='{.status.conditions[0].status}')
  if [[ "$status" != "True" ]]; then
    echo "⚠️ Le certificat $cert n'est pas prêt (statut: $status)"
  else
    echo "✅ Certificat $cert prêt"
  fi
done

# 6️⃣ Vérification des Secrets associés aux certificats
echo -e "\n🔐 Vérification des Secrets associés aux certificats..."
kubectl get secrets -n "$NS" | grep tls

# Vérifier si les secrets TLS sont associés aux certificats
for secret in $(kubectl get secrets -n "$NS" -o jsonpath='{.items[*].metadata.name}'); do
  if [[ "$secret" == *"tls-"* ]]; then
    echo "✅ Secret TLS associé: $secret"
  fi
done

# 7️⃣ Vérification des logs de Cert-Manager
echo -e "\n📜 Vérification des logs des pods Cert-Manager..."
for pod in $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].metadata.name}'); do
  echo -e "\n🔍 Logs du pod $pod :"
  kubectl logs "$pod" -n "$NS" --tail=20
done

echo "──────────────────────────────────────────────────────────────"
echo "✅ Sanity check Cert-Manager terminé."
