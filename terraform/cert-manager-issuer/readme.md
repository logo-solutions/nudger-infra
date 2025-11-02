
# Installation du ClusterIssuer Let's Encrypt avec Terraform et Kubernetes

## Contexte
L'objectif de cette installation est de configurer un **ClusterIssuer** pour Let's Encrypt via **ACME DNS-01** dans un cluster Kubernetes. Ce ClusterIssuer permettra d'automatiser la gestion des certificats TLS pour les applications Kubernetes en utilisant **Cloudflare** comme fournisseur DNS pour la validation des défis ACME.

## Démarche

L'installation a été réalisée en utilisant **Terraform** pour orchestrer la configuration du ClusterIssuer et du secret Cloudflare API. Voici les étapes détaillées du processus :

### 1. Application du plan Terraform
La commande suivante a été utilisée pour appliquer les changements :
```bash
terraform apply -auto-approve   -var "email=loicgourmelon@gmail.com"   -var "dns_zone=logo-solutions.fr"   -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)"
```

#### Résultat de l'exécution
- **Secret Cloudflare API Token** : Création du secret Kubernetes pour stocker l'API Token Cloudflare utilisé pour valider les défis DNS-01.
- **ClusterIssuer `letsencrypt-dns`** : Création du **ClusterIssuer** pour Let's Encrypt dans le namespace `cert-manager`.
  - Utilisation de l'API ACME pour la gestion des certificats via **Cloudflare** comme solvers DNS-01.
  - L'email utilisé pour la configuration est `loicgourmelon@gmail.com`.
  - **API Token Cloudflare** est récupéré depuis un coffre Bitwarden via `bw get item`.

### 2. Création des ressources Kubernetes
Terraform a créé les ressources suivantes dans Kubernetes :
- **Secret Kubernetes** `cloudflare-api-token-secret` : Stocke l'API token de Cloudflare pour interagir avec l'API de Cloudflare.
- **ClusterIssuer** `letsencrypt-dns` : Un ClusterIssuer pour cert-manager qui utilise **Cloudflare** pour la validation DNS des certificats Let's Encrypt.

### 3. Vérification de l'installation
Pour vérifier l'état du déploiement, les commandes suivantes ont été utilisées :
```bash
kubectl get ns
kubectl get all -n cert-manager
```

#### Résultats
- Les **Pods** associés à **Cert-Manager** sont en état **Running**, ce qui confirme que **Cert-Manager** et le **ClusterIssuer** sont opérationnels.
- Le **Deployment** et les **ReplicaSets** associés ont été créés et sont en fonctionnement, garantissant la haute disponibilité des composants de Cert-Manager.

### 4. Bilan
- **Terraform** a permis de gérer l'installation du **ClusterIssuer Let's Encrypt** via **Helm** de manière **automatisée et sécurisée**, garantissant une installation cohérente et reproductible à chaque fois.
- **Cert-Manager** est maintenant prêt à gérer les certificats TLS via Let's Encrypt, avec une validation DNS-01 automatique via **Cloudflare**.
- Cette démarche simplifie l'acquisition et le renouvellement des certificats TLS dans le cluster Kubernetes.

## Conclusion
Cette installation a permis d'automatiser le déploiement du **ClusterIssuer Let's Encrypt** via **Terraform** et **Kubernetes**. Le processus a été fluide, rapide, et facilement reproductible dans différents environnements Kubernetes.


