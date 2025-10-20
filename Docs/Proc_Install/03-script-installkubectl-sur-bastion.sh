#!/bin/bash
set -euo pipefail

# === Vérification des paramètres =====================
if [ $# -ne 1 ]; then
  echo "Usage: $0 <MASTER_IP>"
  exit 1
fi

MASTER_IP="$1"
MASTER_USER="root"
REMOTE_KUBECONFIG_PATH="/root/.kube/config"
LOCAL_KUBECONFIG_PATH="$HOME/.kube/config"
# ============================================

echo "🔧 Installation de kubectl (v1.29)..."
apt update -qq
apt install -y -qq curl apt-transport-https gnupg ca-certificates

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg

echo "deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt update -qq
apt install -y -qq kubectl

echo "✅ kubectl installé : version $(kubectl version --client --short)"

echo "📦 Création du dossier ~/.kube si besoin"
mkdir -p "$HOME/.kube"

echo "🔐 Récupération du fichier kubeconfig depuis $MASTER_IP"
scp -i ~/.ssh/hetzner-bastion "${MASTER_USER}@${MASTER_IP}:${REMOTE_KUBECONFIG_PATH}" "$LOCAL_KUBECONFIG_PATH"

echo "🧪 Test de connexion au cluster..."
kubectl get nodes

echo "✅ Configuration terminée. Tu peux maintenant utiliser kubectl et Terraform depuis Bastion."
