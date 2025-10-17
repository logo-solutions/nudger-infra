#!/bin/bash
# =====================================================================
# 🔄 reset-vault.sh — Réinitialise complètement Vault et son stockage
# ---------------------------------------------------------------------
# Supprime :
#   - le namespace vault
#   - les PVC / PV associés
#   - les volumes Longhorn
#   - nettoie les finalizers bloquants
# Puis attend que tout soit supprimé avant de relancer le déploiement.
# =====================================================================

set -euo pipefail

NAMESPACE="vault"
LONGHORN_NS="longhorn-system"

echo "🚨 Réinitialisation complète de Vault et du stockage associé"
echo "🔍 Namespace ciblé : ${NAMESPACE}"

# ───────────────────────────────
# 1️⃣ Suppression du namespace Vault
# ───────────────────────────────
echo "🧹 Suppression du namespace Vault..."
kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true --wait=false

# ───────────────────────────────
# 2️⃣ Suppression des PV/PVC liés à Vault
# ───────────────────────────────
echo "📦 Suppression des PV/PVC liés à Vault..."
kubectl get pvc -A | grep "${NAMESPACE}" || echo "Aucun PVC Vault trouvé."
kubectl get pv | grep "${NAMESPACE}" || echo "Aucun PV Vault trouvé."

# Patch finalizers (si PVC bloqués)
echo "🩹 Suppression des finalizers sur les PVC (si nécessaire)..."
for pvc in $(kubectl get pvc -n "${NAMESPACE}" -o name 2>/dev/null || true); do
  kubectl patch "$pvc" -n "${NAMESPACE}" -p '{"metadata":{"finalizers":null}}' --type=merge || true
done

# Supprimer tous les PVC et PV résiduels
kubectl delete pvc -n "${NAMESPACE}" --all --ignore-not-found=true || true
kubectl delete pv --all --ignore-not-found=true || true

# ───────────────────────────────
# 3️⃣ Suppression des volumes Longhorn liés à Vault
# ───────────────────────────────
echo "🧱 Nettoyage des volumes Longhorn (Vault)..."
for vol in $(kubectl -n ${LONGHORN_NS} get volumes -o name 2>/dev/null | grep vault || true); do
  kubectl -n ${LONGHORN_NS} delete "$vol" || true
done

# ───────────────────────────────
# 4️⃣ Attente de la disparition complète
# ───────────────────────────────
echo "⏳ Attente de la suppression complète..."
sleep 5
kubectl get pv,pvc -A | grep "${NAMESPACE}" || echo "✅ Plus aucun PV/PVC Vault"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 && echo "⚠️ Namespace encore présent..." || echo "✅ Namespace supprimé"
kubectl -n ${LONGHORN_NS} get volumes | grep vault || echo "✅ Plus aucun volume Longhorn Vault"

# ───────────────────────────────
# 5️⃣ (Optionnel) Réinitialisation du dossier local sur le master
# ───────────────────────────────
MASTER_IP="91.98.16.184"
MASTER_KEY="/root/.ssh/hetzner-bastion"
echo "🧽 Nettoyage du répertoire de stockage local sur le master..."
ssh -i "$MASTER_KEY" -o StrictHostKeyChecking=no root@"$MASTER_IP" "rm -rf /var/lib/vault/data/* || true"

# ───────────────────────────────
# 6️⃣ Relance propre du déploiement Terraform
# ───────────────────────────────
echo "🚀 Relancer ensuite manuellement :"
echo "   cd ~/nudger-infra/terraform/vault-storage && terraform apply -auto-approve"
echo "   cd ~/nudger-infra/terraform/vault && terraform apply -auto-approve"
echo ""
echo "🏁 Réinitialisation terminée."
echo "# 1️⃣ Recrée le stockage local pour Vault
cd ~/nudger-infra/terraform/vault-storage
terraform apply -auto-approve

# 2️⃣ Redéploie Vault lui-même
cd ~/nudger-infra/terraform/vault
terraform apply -auto-approve"
echo "attendre que le pod passe en runinng"
echo "# 3️⃣ Initialisation propre
kubectl exec -n vault -it vault-0 -- sh
vault operator init -key-shares=1 -key-threshold=1 -format=json > /tmp/vault-init.json
exit
kubectl cp vault/vault-0:/tmp/vault-init.json /root/.ansible/artifacts/master1/vault-k8s-init.json

# 4️⃣ Déverrouillage
export VAULT_ADDR=http://127.0.0.1:8200
kubectl port-forward -n vault svc/vault 8200:8200 &
vault operator unseal $(jq -r '.unseal_keys_b64[0]' /root/.ansible/artifacts/master1/vault-k8s-init.json)
vault status"
echo "export VAULT_ADDR=http://127.0.0.1:8200"
echo "export VAULT_TOKEN=$(jq -r '.root_token' /root/.ansible/artifacts/master1/vault-k8s-init.json)	"
echo "vault login $VAULT_TOKEN"

