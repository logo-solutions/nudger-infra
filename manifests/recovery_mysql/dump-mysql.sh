#!/bin/bash

# Paramètres de la base de données
MYSQL_POD_NAME=$(kubectl get pods -n integration -l app=mysql -o jsonpath='{.items[0].metadata.name}')

MYSQL_NAMESPACE="integration"
MYSQL_DB_NAME="xwiki"
MYSQL_USER="root"
MYSQL_PASSWORD="xwiki"

# Nom du fichier de dump
DUMP_FILE="/tmp/xwiki-db-dump.sql"

# Étape 1 : Effectuer le dump de la base de données dans le pod
echo "📝 Effectuer le dump de la base de données XWiki..."
kubectl exec -it $MYSQL_POD_NAME -n $MYSQL_NAMESPACE -- \
  mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DB_NAME > $DUMP_FILE

# Vérification si le dump a réussi
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de la création du dump."
  exit 1
fi

echo "✅ Dump effectué avec succès."

# Étape 2 : Copier le fichier dump depuis le pod vers le système local
echo "📤 Copier le dump du pod vers le système local..."

kubectl cp $MYSQL_NAMESPACE/$MYSQL_POD_NAME:$DUMP_FILE ./xwiki-db-dump.sql

# Vérification si le copy a réussi
if [ $? -ne 0 ]; then
  echo "❌ Erreur lors de la copie du fichier dump."
  exit 1
fi

echo "✅ Dump copié avec succès sur le système local : ./xwiki-db-dump.sql"
