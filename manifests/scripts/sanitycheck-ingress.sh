#!/bin/bash

# Variables
NAMESPACE="recette"
SERVICE_NAME="xwiki"
INGRESS_NAME="xwiki"
TLS_SECRET_NAME="tls-xwiki"
INGRESS_CLASS="nginx"
HOST="xwiki.recette.nudger.logo-solutions.fr"
PORT_HTTP=80
PORT_HTTPS=443

# Function to check if a pod is running
check_pod_status() {
    echo "🔍 Vérification de l'état des pods dans le namespace '$NAMESPACE'..."
    kubectl get pods -n "$NAMESPACE" --no-headers | grep -i "xwiki" | awk '{print $1, $3}'
}

# Function to check if the service is correctly exposed
check_service() {
    echo "🔍 Vérification du service '$SERVICE_NAME' dans le namespace '$NAMESPACE'..."
    kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o yaml | grep -i "port"
}

# Function to check the ingress resource
check_ingress() {
    echo "🔍 Vérification de l'ingress '$INGRESS_NAME' dans le namespace '$NAMESPACE'..."
    kubectl get ingress -n "$NAMESPACE" "$INGRESS_NAME" -o yaml
}

# Function to check the TLS certificate status
check_tls_certificate() {
    echo "🔍 Vérification du certificat TLS '$TLS_SECRET_NAME' dans le namespace '$NAMESPACE'..."
    kubectl describe certificate "$TLS_SECRET_NAME" -n "$NAMESPACE" | grep -E "Ready|Not After|Not Before"
}

# Function to check the HTTP connectivity to the ingress host
check_http_connectivity() {
    echo "🔍 Vérification de la connectivité HTTP vers $HOST:$PORT_HTTP..."
    curl -vk "http://$HOST:$PORT_HTTP" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Connecté avec succès via HTTP sur le port $PORT_HTTP."
    else
        echo "❌ Échec de la connexion HTTP sur le port $PORT_HTTP."
    fi
}

# Function to check the HTTPS connectivity to the ingress host
check_https_connectivity() {
    echo "🔍 Vérification de la connectivité HTTPS vers $HOST:$PORT_HTTPS..."
    curl -vk "https://$HOST:$PORT_HTTPS" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Connecté avec succès via HTTPS sur le port $PORT_HTTPS."
    else
        echo "❌ Échec de la connexion HTTPS sur le port $PORT_HTTPS."
    fi
}

# Function to check for errors in ingress-controller logs
check_ingress_controller_logs() {
    echo "🔍 Vérification des logs du contrôleur Ingress '$INGRESS_CLASS'..."
    kubectl logs -n ingress-nginx -l app=ingress-nginx-controller --tail=20
}

# Sanity check execution
echo "🔄 Démarrage du sanity check..."

check_pod_status
check_service
check_ingress
check_tls_certificate
check_http_connectivity
check_https_connectivity
check_ingress_controller_logs

echo "✅ Sanity check terminé."
