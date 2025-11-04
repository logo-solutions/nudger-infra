#!/bin/bash

# Variables
NAMESPACE="integration"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=xwiki-frontend -o jsonpath='{.items[0].metadata.name}')
MYSQL_HOST="mysql.integration.svc.cluster.local"
MYSQL_USER="xwiki"
MYSQL_PASSWORD="xwiki"
MYSQL_DB="xwiki"

# Tester la connexion et afficher les tables
echo "🎯 Tentative de connexion à MySQL sur $MYSQL_HOST..."

kubectl exec -it $POD_NAME -n $NAMESPACE -- /bin/sh -c "
    echo '🔌 Connexion à MySQL...';
    mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e 'SHOW TABLES;' $MYSQL_DB
"
