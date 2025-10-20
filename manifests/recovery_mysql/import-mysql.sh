#!/bin/bash

# Nom du pod MySQL de récupération
POD_NAME="mysql-recovery-7c8f776ff-gthxj"
NAMESPACE="xwiki"

# Emplacement du fichier de dump dans ton système local
DUMP_FILE="./xwiki-db-dump.sql"
POD_DEST_PATH="/tmp/xwiki-db-dump.sql"

# Étape 1 : Vérifier si le fichier de dump existe
if [ ! -f "$DUMP_FILE" ]; then
  echo "❌ Fichier de dump introuvable : $DUMP_FILE"
  exit 1
fi

# Étape 2 : Copier le fichier de dump dans le pod
echo "📤 Copier le fichier de dump dans le pod..."
kubectl cp $DUMP_FILE $NAMESPACE/$POD_NAME:$POD_DEST_PATH

# Vérification si la copie a réussi
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de la copie du fichier de dump dans le pod."
  exit 1
fi

echo "✅ Fichier de dump copié dans le pod avec succès."

# Étape 3 : Importer le fichier de dump dans la base de données XWiki
echo "📥 Importer le dump dans la base de données XWiki..."
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "mysql -u root -pxwiki xwiki < $POD_DEST_PATH"

# Vérification si l'importation a réussi
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de l'importation du dump dans la base de données."
  exit 1
fi

echo "✅ Importation du dump réussie dans la base de données XWiki."

# Étape 4 : Vérification de l'importation en listant les tables
echo "🧐 Vérification des tables dans la base de données XWiki..."
kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "mysql -u root -pxwiki -e 'SHOW TABLES;' xwiki"

# Conclusion
echo "✅ L'importation et la vérification ont été effectuées avec succès."
