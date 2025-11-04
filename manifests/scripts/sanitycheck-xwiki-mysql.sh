#!/bin/bash

# Définir le namespace
NAMESPACE="integration"

# Vérifier si le namespace existe
echo "🔍 Vérification du namespace '$NAMESPACE'..."
kubectl get ns "$NAMESPACE" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Namespace '$NAMESPACE' introuvable."
  exit 1
else
  echo "✅ Namespace '$NAMESPACE' trouvé."
fi

# Vérification des pods MySQL et XWiki
echo -e "\n📦 Vérification des pods MySQL et XWiki..."

MYSQL_STATUS=$(kubectl get pod -n "$NAMESPACE" -l app=mysql -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Absent")
XWIKI_STATUS=$(kubectl get pod -n "$NAMESPACE" -l app=xwiki -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Absent")

# Vérifier le statut de MySQL
if [[ "$MYSQL_STATUS" == "Running" ]]; then
  echo "✅ Pod MySQL opérationnel"
else
  echo "⚠️ Pod MySQL non prêt (état: $MYSQL_STATUS)"
  kubectl logs -n "$NAMESPACE" -l app=mysql || echo "❌ Erreur lors de l'affichage des logs MySQL"
fi

# Vérifier le statut de XWiki
if [[ "$XWIKI_STATUS" == "Running" ]]; then
  echo "✅ Pod XWiki opérationnel"
else
  echo "⚠️ Pod XWiki non prêt (état: $XWIKI_STATUS)"
  kubectl logs -n "$NAMESPACE" -l app=xwiki || echo "❌ Erreur lors de l'affichage des logs XWiki"
fi

# Vérification des services MySQL et XWiki
echo -e "\n🌐 Vérification des services MySQL et XWiki..."
kubectl get svc -n "$NAMESPACE"

# Vérification des endpoints MySQL et XWiki
echo -e "\n🔗 Vérification des endpoints MySQL et XWiki..."
kubectl get endpoints -n "$NAMESPACE"

# Vérification de la connectivité entre XWiki et MySQL
echo -e "\n🧪 Test de connectivité MySQL depuis XWiki..."
MYSQL_POD=$(kubectl get pod -n "$NAMESPACE" -l app=mysql -o jsonpath='{.items[0].metadata.name}')
XWIKI_POD=$(kubectl get pod -n "$NAMESPACE" -l app=xwiki -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n "$NAMESPACE" "$XWIKI_POD" -- mysqladmin ping -h "$MYSQL_POD" -u root -pxwiki >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ XWiki peut se connecter à MySQL."
else
  echo "❌ Problème de connectivité entre XWiki et MySQL."
  exit 1
fi

# Vérification des PersistentVolumeClaims
echo -e "\n💾 Vérification des volumes persistants MySQL et XWiki..."
kubectl get pvc -n "$NAMESPACE"

# Vérification des certificats SSL
echo -e "\n🔐 Vérification des certificats SSL pour l'Ingress..."
kubectl get certificates -n "$NAMESPACE"

# Vérification de l'Ingress
echo -e "\n🔍 Vérification de l'Ingress pour XWiki..."
kubectl describe ingress xwiki -n "$NAMESPACE"

# Vérification de la connectivité externe via HTTPS
echo -e "\n🌍 Vérification de la connectivité HTTPS..."
curl -vk https://xwiki.nudger.logo-solutions.fr:30443

echo -e "\n🎯 Sanity check terminé."
