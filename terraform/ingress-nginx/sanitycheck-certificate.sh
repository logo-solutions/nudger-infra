#!/bin/bash

# Variables pour les namespaces et les certificats
NAMESPACE_RECETTE="recette"
NAMESPACE_INTEGRATION="integration"
CERTIFICATE_NAME="tls-xwiki"
SECRET_NAME="tls-xwiki"
INGRESS_NAME="xwiki"
DOMAIN_NAME_RECETTE="xwiki.recette.nudger.logo-solutions.fr"
DOMAIN_NAME_INTEGRATION="xwiki.integration.nudger.logo-solutions.fr"

echo "🔄 Démarrage du sanity check..."

# Fonction de vérification pour les deux environnements : Recette et Intégration
check_certificate() {
  local namespace=$1
  local domain_name=$2

  echo "🔍 Vérification de l'existence du certificat '$CERTIFICATE_NAME' dans le namespace '$namespace'..."
  CERT_STATUS=$(kubectl get certificate $CERTIFICATE_NAME -n $namespace -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
  if [[ "$CERT_STATUS" == "True" ]]; then
      echo "✅ Le certificat '$CERTIFICATE_NAME' est prêt."
  else
      echo "❌ Le certificat '$CERTIFICATE_NAME' n'est pas prêt."
      exit 1
  fi

  # Vérification du secret associé
  echo "🔍 Vérification du secret associé '$SECRET_NAME' dans le namespace '$namespace'..."
  SECRET_EXISTS=$(kubectl get secret $SECRET_NAME -n $namespace --ignore-not-found)
  if [[ -n "$SECRET_EXISTS" ]]; then
      echo "✅ Le secret '$SECRET_NAME' existe dans le namespace '$namespace'."
  else
      echo "❌ Le secret '$SECRET_NAME' n'existe pas dans le namespace '$namespace'."
      exit 1
  fi

  # Vérification de l'Ingress
  echo "🔍 Vérification de l'Ingress '$INGRESS_NAME' dans le namespace '$namespace'..."
  INGRESS_HOST=$(kubectl get ingress $INGRESS_NAME -n $namespace -o jsonpath='{.spec.rules[0].host}')
  if [[ "$INGRESS_HOST" == "$domain_name" ]]; then
      echo "✅ L'Ingress '$INGRESS_NAME' pointe bien sur le domaine '$domain_name'."
  else
      echo "❌ L'Ingress '$INGRESS_NAME' ne pointe pas sur le domaine attendu."
      exit 1
  fi

  # Vérification de la connectivité HTTPS
  echo "🔍 Vérification de la connectivité HTTPS vers '$domain_name'..."
  HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$domain_name)
  if [[ "$HTTPS_RESPONSE" -eq 200 ]]; then
      echo "✅ La connexion HTTPS vers '$domain_name' fonctionne correctement."
  else
      echo "❌ Échec de la connexion HTTPS vers '$domain_name'. Code de réponse: $HTTPS_RESPONSE"
      exit 1
  fi

  # Vérification de l'état de l'Ingress
  echo "🔍 Vérification de l'état de l'Ingress '$INGRESS_NAME' dans le namespace '$namespace'..."
  INGRESS_STATUS=$(kubectl get ingress $INGRESS_NAME -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [[ -n "$INGRESS_STATUS" ]]; then
      echo "✅ L'Ingress a une adresse IP: $INGRESS_STATUS"
  else
      echo "❌ L'Ingress ne semble pas avoir d'adresse IP associée."
      exit 1
  fi
}

# Vérification pour le namespace recette
echo "🔄 Démarrage du sanity check pour le namespace 'recette'..."
check_certificate $NAMESPACE_RECETTE $DOMAIN_NAME_RECETTE

# Vérification pour le namespace intégration
echo "🔄 Démarrage du sanity check pour le namespace 'integration'..."
check_certificate $NAMESPACE_INTEGRATION $DOMAIN_NAME_INTEGRATION

echo "✅ Sanity check du certificat terminé."
