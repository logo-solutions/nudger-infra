#!/bin/bash

# Variables
NAMESPACE="integration"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}')
POD_DEST_PATH="/root/nudger-infra/manifests/recovery_mysql/xwiki-db-dump.sql"
LOCAL_DUMP_PATH="./xwiki-db-dump.sql"
TEMP_DEST_PATH="/tmp/xwiki-db-dump.sql"

# Vérification de l'existence du pod
if [ -z "$POD_NAME" ]; then
  echo "❌ Aucun pod mysqly trouvé dans le namespace $NAMESPACE"
  exit 1
fi

echo "📦 Pod cible : $POD_NAME dans le namespace $NAMESPACE"

# Copier le fichier de dump dans le pod
echo "📤 Copie du fichier de dump dans le pod..."
kubectl cp $LOCAL_DUMP_PATH $NAMESPACE/$POD_NAME:$TEMP_DEST_PATH

# Vérification de la copie
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de la copie du fichier de dump."
  exit 1
fi

echo "✅ Fichier de dump copié avec succès."

# Importer le dump dans la base MySQL
echo "📥 Importation du dump dans la base MySQL..."
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "mysql -u root -pxwiki xwiki < $TEMP_DEST_PATH"

# Vérification de l'importation
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de l'importation du dump."
  exit 1
fi

echo "✅ Importation réussie."

# Vérification des tables dans la base XWiki
echo "🧐 Vérification des tables dans la base XWiki..."
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "mysql -u root -pxwiki -e 'SHOW TABLES;' xwiki"

# Conclusion
echo "✅ L'importation et la vérification des tables ont été effectuées avec succès."
