#!/usr/bin/env bash
set -euo pipefail

NS="xwiki"
echo -e "\n🔒 Vérification des Ingress dans le namespace: ${NS}"
echo "──────────────────────────────────────────────────────────────"

# 7️⃣ Vérification des Ingress
echo -e "\n🔒 Vérification des Ingress..."
INGRESS_LIST=$(kubectl get ingress -n "$NS" -o jsonpath='{.items[*].metadata.name}' || echo "none")
if [[ "$INGRESS_LIST" == "none" ]]; then
  echo "❌ Aucun Ingress trouvé dans le namespace $NS"
  exit 1
fi

# Boucle sur chaque Ingress pour vérifier le certificat TLS
for ingress in $INGRESS_LIST; do
  echo -e "\n📝 Vérification de l'Ingress: $ingress"
  
  # Vérifier si un certificat TLS est attaché à l'Ingress
  tls_cert=$(kubectl get ingress "$ingress" -n "$NS" -o jsonpath='{.spec.tls[0].secretName}' || echo "none")
  if [[ "$tls_cert" != "none" ]]; then
    echo "✅ Certificat TLS attaché à l'Ingress $ingress : $tls_cert"
  else
    echo "⚠️ Aucun certificat TLS attaché à l'Ingress $ingress"
  fi

  # Vérification des hosts
  hosts=$(kubectl get ingress "$ingress" -n "$NS" -o jsonpath='{.spec.rules[*].host}' || echo "none")
  if [[ "$hosts" != "none" ]]; then
    echo "🖥️ Hosts associés à l'Ingress $ingress : $hosts"
  else
    echo "⚠️ Aucun host associé à l'Ingress $ingress"
  fi

  # Vérification de la connectivité HTTP
  echo -e "\n🌍 Test de connectivité HTTP sur l'Ingress $ingress..."
  http_response=$(curl -s -L -o /dev/null -w "%{http_code}" "http://$hosts" || echo "none")
  if [[ "$http_response" == "200" || "$http_response" == "302" ]]; then
    echo "✅ Ingress $ingress répond correctement (HTTP $http_response)"
  else
    echo "❌ L'Ingress $ingress ne répond pas comme prévu (HTTP $http_response)"
  fi

  # Vérification de la validité du certificat TLS via openssl (si TLS attaché)
  if [[ "$tls_cert" != "none" ]]; then
    echo -e "\n🔐 Vérification de la validité du certificat TLS pour $ingress..."
    cert_check=$(echo | openssl s_client -connect "$hosts":443 -servername "$hosts" 2>/dev/null | openssl x509 -noout -dates || echo "invalid")
    if [[ "$cert_check" != "invalid" ]]; then
      echo "✅ Certificat TLS valide pour l'Ingress $ingress"
    else
      echo "❌ Certificat TLS invalide pour l'Ingress $ingress"
    fi
  fi
done

echo "──────────────────────────────────────────────────────────────"
echo "✅ Vérification des Ingress terminée."
