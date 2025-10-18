#!/usr/bin/env bash
set -euo pipefail

NS="xwiki"
echo "🔍 [SANITY CHECK] Vérification de l'environnement XWiki (namespace: ${NS})"
echo "──────────────────────────────────────────────────────────────"

# 1️⃣ Vérifier le namespace
if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "❌ Namespace $NS introuvable"
  exit 1
fi
echo "✅ Namespace $NS présent"

# 2️⃣ Vérifier les pods
echo -e "\n📦 Vérification des Pods..."
kubectl get pods -n "$NS" -o wide

MYSQL_STATUS=$(kubectl get pod -n "$NS" -l app=mysql -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Absent")
XWIKI_STATUS=$(kubectl get pod -n "$NS" -l app=xwiki -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Absent")

if [[ "$MYSQL_STATUS" == "Running" ]]; then
  echo "✅ Pod MySQL opérationnel"
else
  echo "⚠️ Pod MySQL non prêt (état: $MYSQL_STATUS)"
  echo "→ Derniers logs MySQL :"
  kubectl logs -n "$NS" -l app=mysql --tail=20 || true
fi

if [[ "$XWIKI_STATUS" == "Running" ]]; then
  echo "✅ Pod XWiki opérationnel"
else
  echo "⚠️ Pod XWiki non prêt (état: $XWIKI_STATUS)"
  echo "→ Derniers logs XWiki :"
  kubectl logs -n "$NS" -l app=xwiki --tail=20 || true
fi

# 3️⃣ Vérifier les services
echo -e "\n🌐 Vérification des Services..."
kubectl get svc -n "$NS"

if kubectl get svc -n "$NS" mysql >/dev/null 2>&1; then
  echo "✅ Service MySQL OK"
else
  echo "❌ Service MySQL manquant"
fi

if kubectl get svc -n "$NS" xwiki >/dev/null 2>&1; then
  echo "✅ Service XWiki OK"
else
  echo "❌ Service XWiki manquant"
fi

# 4️⃣ Vérifier les PVC
echo -e "\n💾 Vérification des volumes persistants..."
kubectl get pvc -n "$NS" || true

PV_STATE=$(kubectl get pvc -n "$NS" -o jsonpath='{.items[*].status.phase}' || echo "none")
if [[ "$PV_STATE" == *"Bound"* ]]; then
  echo "✅ Volumes attachés"
else
  echo "⚠️ Volumes non attachés : $PV_STATE"
fi

# 5️⃣ Vérifier readiness MySQL (connexion interne)
echo -e "\n🧪 Test de connectivité MySQL..."
MYSQL_POD=$(kubectl get pod -n "$NS" -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "$MYSQL_POD" ]]; then
  kubectl exec -n "$NS" "$MYSQL_POD" -- bash -c "mysqladmin ping -u root -pxwiki >/dev/null 2>&1" \
    && echo "✅ MySQL répond" || echo "❌ MySQL ne répond pas encore"
else
  echo "⚠️ Aucun pod MySQL détecté"
fi

# 6️⃣ Vérifier readiness HTTP XWiki
echo -e "\n🌍 Vérification du service HTTP XWiki..."
if kubectl run xwiki-test --rm -i --restart=Never -n "$NS" \
  --image=curlimages/curl:8.8.0 -- \
  curl -s -o /dev/null -w "%{http_code}" http://xwiki.xwiki.svc.cluster.local | grep -qE "200|302"; then
  echo "✅ XWiki répond en HTTP"
else
  echo "❌ XWiki ne répond pas encore sur le service interne"
fi

echo "──────────────────────────────────────────────────────────────"
echo "✅ Sanity check terminé."
