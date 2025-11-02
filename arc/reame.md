
# Installation de ARC (GitHub Actions Runner Controller) avec Terraform et Kubernetes

## Contexte
L'objectif de cette installation est de déployer **ARC (GitHub Actions Runner Controller)** sur un cluster Kubernetes afin de gérer les **runners GitHub Actions** de manière automatisée. Cela permet d'exécuter des jobs CI/CD directement dans un cluster Kubernetes, avec la possibilité de scaler dynamiquement les runners en fonction des besoins.

## Démarche

L'installation de **ARC** a été réalisée en utilisant **Terraform** et **Helm** pour automatiser le déploiement. Voici les étapes détaillées du processus :

### 1. Application du plan Terraform
La commande suivante a été utilisée pour appliquer les changements :
```bash
terraform apply -auto-approve   -var "email=loicgourmelon@gmail.com"   -var "dns_zone=logo-solutions.fr"   -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)"
```

#### Résultat de l'exécution
- **Secrets GitHub** : Le secret GitHub App est créé et stocké pour une utilisation future dans le cluster Kubernetes.
- **Déploiement du contrôleur ARC** : Le contrôleur **GitHub Actions Runner Controller** est installé dans le namespace `arc` à l'aide du chart Helm `gha-runner-scale-set-controller`.
- **Déploiement du runner** : Le runner **nudger-runner** est déployé pour exécuter des jobs GitHub Actions dans le cluster.

### 2. Création des ressources Kubernetes
Terraform a créé les ressources suivantes dans Kubernetes :
- **Namespace** `arc` : Création du namespace pour organiser les ressources liées à ARC.
- **Helm release** `arc` et `nudger-runner` : Déploiement des ressources nécessaires pour exécuter les actions GitHub dans le cluster Kubernetes.

### 3. Vérification de l'installation
Pour vérifier l'état du déploiement, les commandes suivantes ont été utilisées :
```bash
kubectl get ns
kubectl get all -n arc
```

#### Résultats
- Les **Pods** associés au contrôleur **ARC** et aux **runners** GitHub sont en état **Running**, ce qui confirme que le système est opérationnel.
- Le **Deployment** et les **ReplicaSets** associés ont été créés et sont en fonctionnement, garantissant la haute disponibilité des runners.

### 4. Bilan
- **Terraform** a permis de gérer l'installation du **GitHub Actions Runner Controller (ARC)** de manière **automatisée et sécurisée**, garantissant une installation cohérente et reproductible.
- Le **runner** GitHub `nudger-runner` est maintenant prêt à exécuter des jobs dans le cluster Kubernetes.
- Cette démarche facilite la gestion des runners GitHub Actions en permettant leur **scalabilité automatique** et leur gestion centralisée dans Kubernetes.

## Conclusion
Cette installation a permis d'automatiser le déploiement de **ARC (GitHub Actions Runner Controller)** via **Terraform** et **Helm** dans Kubernetes. Le processus a été fluide, rapide, et facilement reproductible, offrant une gestion optimale des workflows CI/CD dans Kubernetes.


