
# Installation d'Ingress NGINX avec Terraform et Helm

## Contexte
L'objectif de cette installation est de déployer **Ingress NGINX** dans un cluster Kubernetes afin de gérer l'acheminement du trafic HTTP/HTTPS vers les services Kubernetes. Cette approche permet de centraliser la gestion du trafic entrant tout en offrant une solution évolutive et configurable.

## Démarche

L'installation d'**Ingress NGINX** a été réalisée en utilisant **Terraform** pour gérer l'installation via **Helm**. Voici les étapes détaillées du processus :

### 1. Application du plan Terraform
La commande suivante a été utilisée pour appliquer les changements :
```bash
terraform apply -auto-approve
```

#### Résultat de l'exécution
- **Namespace `ingress-nginx`** : Création du namespace `ingress-nginx` pour organiser les ressources liées à Ingress NGINX.
- **Helm release `ingress-nginx`** : Installation du chart Helm pour Ingress NGINX dans le namespace `ingress-nginx`.
  - La configuration inclut la gestion des services **NodePort** pour l'accès HTTP (30080) et HTTPS (30443).
  - Le certificat SSL par défaut est configuré avec `default-ssl-certificate: "xwiki/tls-xwiki"`.
  - La mise en place des **webhooks d'admission** et des paramètres associés a été activée.

### 2. Création des ressources Kubernetes
Terraform a créé les ressources suivantes dans Kubernetes :
- **Namespace** `ingress-nginx` : Création du namespace pour organiser les ressources liées à Ingress NGINX.
- **Helm release** `ingress-nginx` : Déploiement de Ingress NGINX avec la configuration appropriée.

### 3. Vérification de l'installation
Pour vérifier l'état du déploiement, les commandes suivantes ont été utilisées :
```bash
kubectl get ns
kubectl get all -n ingress-nginx
```

#### Résultats
- Le **Pod** `ingress-nginx-controller` est en état **Running**, ce qui confirme que le contrôleur Ingress NGINX est opérationnel.
- Les **Services** associés à Ingress NGINX sont exposés via les ports **30080 (HTTP)** et **30443 (HTTPS)** pour un accès externe au cluster.
- Le **Deployment** et les **ReplicaSets** associés ont été créés et sont en fonctionnement, garantissant la haute disponibilité du contrôleur.

### 4. Bilan
- **Terraform** a permis de gérer l'installation du **contrôleur Ingress NGINX** via **Helm** de manière **automatisée et sécurisée**, garantissant une installation cohérente et reproductible à chaque fois.
- **Ingress NGINX** est maintenant prêt à être utilisé pour gérer les requêtes HTTP et HTTPS dans le cluster Kubernetes.

## Conclusion
Cette installation a permis d'automatiser le déploiement du **contrôleur Ingress NGINX** via **Terraform** et **Helm**, avec une gestion centralisée du trafic entrant. Le processus a été fluide, rapide, et facilement reproductible dans différents environnements Kubernetes.


