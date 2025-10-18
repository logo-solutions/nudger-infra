#!/usr/bin/env bash
set -euo pipefail

NS="xwiki"
MYSQL_LABEL="app=mysql"
XWIKI_LABEL="app=xwiki"
MASTER_IP="${1:-}"

SSH_OPTS="-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -i ~/.ssh/hetzner-bastion"

echo "🧨 RESET COMPLET de XWiki (namespace, PV, PVC, stockage local)"
echo "──────────────────────────────────────────────────────────────"

if [[ -z "$MASTER_IP" ]]; then
  echo "❌ ERREUR : tu dois fournir l'adresse IP du nœud master."
  echo "   Exemple : $0 91.98.16.184"
  exit 1
fi

read -r -p "Confirmer la suppression complète (y/N) ? " confirm
[[ "${confirm,,}" != "y" ]] && echo "❌ Annulé." && exit 0

# Étape 1 — Namespace & Helm
echo "🔍 Étape 1 — Suppression du namespace et des releases Helm..."
kubectl delete helmrelease -n "$NS" --all --ignore-not-found >/dev/null 2>&1 || true
kubectl delete ns "$NS" --force --grace-period=0 || true

# Étape 2 — PV/PVC
echo "🧹 Étape 2 — Suppression des PVC/PV..."
kubectl delete pvc,pv -A -l "$XWIKI_LABEL" --ignore-not-found || true
kubectl delete pvc,pv -A -l "$MYSQL_LABEL" --ignore-not-found || true
kubectl delete pvc -n "$NS" data-mysql-0 --force --grace-period=0 || true

for pv in $(kubectl get pv | awk '/mysql/{print $1}'); do
  echo "🗑 Suppression du PV $pv"
  kubectl patch pv "$pv" -p '{"metadata":{"finalizers":null}}' --type=merge >/dev/null 2>&1 || true
  kubectl delete pv "$pv" --force --grace-period=0 || true
done

# Étape 3 — Détection du node
echo "🧠 Étape 3 — Détection du nœud MySQL..."
MYSQL_NODE=$(kubectl get pods -A -l app=mysql -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null || echo "")
if [[ -z "$MYSQL_NODE" ]]; then
  MYSQL_NODE=$(kubectl get nodes -o name | head -1 | cut -d'/' -f2)
  echo "⚠️ Aucun pod MySQL actif, on prend le nœud principal : $MYSQL_NODE"
else
  echo "➡️ MySQL tournait sur le nœud : $MYSQL_NODE"
fi

# Étape 4 — Nettoyage du stockage local
echo "🧩 Étape 4 — Nettoyage du stockage local sur $MASTER_IP ..."
SSH_CMD="
  echo '🧹 Suppression des répertoires MySQL sur $MASTER_IP...';
  find /var/lib/rancher/k3s/storage -type d -name '*mysql*' -exec rm -rf {} + 2>/dev/null || true;
  find /opt/local-path-provisioner -type d -name '*mysql*' -exec rm -rf {} + 2>/dev/null || true;
  echo '✅ Purge complète des volumes MySQL terminée sur $MASTER_IP.';
"
ssh $SSH_OPTS "root@$MASTER_IP" "$SSH_CMD" || {
  echo "⚠️ Échec SSH vers $MASTER_IP. Lance manuellement cette commande :"
  echo "   ssh $SSH_OPTS root@$MASTER_IP 'find /var/lib/rancher/k3s/storage -type d -name *mysql* -exec rm -rf {} +'"
}

# Étape 5 — Vérifications
echo "🧾 Étape 5 — Vérifications finales..."
kubectl get pv,pvc -A | grep -E 'mysql|xwiki' || echo "✅ Aucun PV/PVC résiduel"
kubectl get ns "$NS" >/dev/null 2>&1 && echo "⚠️ Namespace encore présent" || echo "✅ Namespace supprimé"

echo "──────────────────────────────────────────────────────────────"
echo "✅ Reset complet terminé."
echo "👉 Pour redéployer :"
echo "   cd /root/nudger-infra/manifests && kubectl apply -f ."
