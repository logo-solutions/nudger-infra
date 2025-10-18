#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="${1:-91.98.16.184}"   # IP de ton master (par défaut Hetzner)
SSH_KEY="${SSH_KEY:-~/.ssh/hetzner-bastion}"
SSH_OPTS="-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -i ${SSH_KEY}"

echo "🌐 Configuration des redirections HTTP/HTTPS sur le nœud ${MASTER_IP}"
echo "──────────────────────────────────────────────────────────────"

# Récupération des NodePorts exposés par le service ingress-nginx-controller
HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
HTTPS_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

if [[ -z "${HTTP_PORT}" || -z "${HTTPS_PORT}" ]]; then
  echo "❌ Impossible de récupérer les NodePorts du service ingress-nginx-controller."
  exit 1
fi

echo "🔎 NodePorts détectés :"
echo "   • HTTP  : ${HTTP_PORT}"
echo "   • HTTPS : ${HTTPS_PORT}"

# Commandes iptables à exécuter sur le master
REMOTE_CMD=$(cat <<EOF
sudo iptables -t nat -C PREROUTING -p tcp --dport 80 -j REDIRECT --to-port ${HTTP_PORT} 2>/dev/null || \
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port ${HTTP_PORT}
sudo iptables -t nat -C PREROUTING -p tcp --dport 443 -j REDIRECT --to-port ${HTTPS_PORT} 2>/dev/null || \
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port ${HTTPS_PORT}
sudo apt-get update -y >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent >/dev/null
sudo netfilter-persistent save
EOF
)

echo "🚀 Application des règles sur ${MASTER_IP}..."
ssh ${SSH_OPTS} root@${MASTER_IP} "${REMOTE_CMD}"

echo "✅ Redirections appliquées et sauvegardées."
echo "🌍 Test final :"
echo "   curl -vkI https://xwiki.nudger.logo-solutions.fr"
echo "──────────────────────────────────────────────────────────────"
