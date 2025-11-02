
# Installation de Local-Path-Provisioner avec Terraform et Helm

## Contexte
L'objectif de cette installation est de configurer **local-path-provisioner** sur un cluster Kubernetes pour gérer les volumes persistants via un **StorageClass** personnalisé appelé `local-path`. Cette approche est particulièrement adaptée pour des environnements de test ou des clusters à nœud unique.

## Démarche

L'installation a été réalisée en utilisant **Terraform** pour orchestrer l'installation et la configuration de Kubernetes via le chart **Helm** du **local-path-provisioner**. Voici les étapes détaillées du processus :

### 1. Application du plan Terraform
La commande suivante a été utilisée pour appliquer les changements :
```bash
terraform apply --auto-approve
```

#### Résultat de l'exécution
- **Namespace `local-path-storage`** : Création du namespace dédié au provisionneur de stockage local.
- **Helm release `local-path-provisioner`** : Installation du chart Helm pour le provisionneur de stockage local dans le namespace `local-path-storage`.
  - L'image Docker `rancher/local-path-provisioner` avec la version `v0.0.32` a été utilisée.
  - Le **StorageClass** `local-path` a été configuré comme **default** avec une politique de suppression **Delete** et un mode de liaison **WaitForFirstConsumer**.

### 2. Détection des changements externes
Lors de l'exécution de Terraform, un message indiquait que des modifications avaient été effectuées en dehors de Terraform, spécifiquement sur le namespace `local-path-storage` (qui avait été supprimé manuellement avant l'application de Terraform). Terraform a pris en charge cette modification en recréant le namespace et les ressources nécessaires.

### 3. Création des ressources Kubernetes
Terraform a ensuite procédé à la création des ressources suivantes :
- **Namespace** `local-path-storage` : Création du namespace pour organiser les ressources liées au stockage local.
- **Helm release** `local-path-provisioner` : Déploiement du provisionneur de stockage local avec la configuration appropriée.

### 4. Vérification de l'installation
Pour vérifier l'état du déploiement, les commandes suivantes ont été utilisées :
```bash
kubectl get po -A
kubectl get po -n local-path-storage
kubectl get all -n local-path-storage
```

#### Résultats
- Le **Pod** `local-path-provisioner` est en état **Running**, ce qui confirme que le provisionneur est opérationnel.
- Le **Deployment** et le **ReplicaSet** associés ont été créés et sont opérationnels, garantissant la haute disponibilité du Pod.

### 5. Bilan
- **Terraform** a permis de gérer l'installation du **local-path-provisioner** via **Helm** de manière **automatisée et sécurisée**, garantissant une installation cohérente et reproductible à chaque fois.
- Le **StorageClass** `local-path` est désormais prêt à être utilisé pour la gestion des volumes persistants dans le cluster Kubernetes.
- Cette démarche offre une solution simple et efficace pour gérer des volumes sur des clusters Kubernetes à nœud unique, avec la possibilité d’évoluer vers une solution plus robuste pour des environnements multi-nœuds.

## Conclusion
Cette installation a permis d'automatiser le déploiement du **local-path-provisioner** via **Terraform** et **Helm**, avec une gestion centralisée du stockage local. Le processus a été fluide, rapide, et facilement reproductible dans différents environnements Kubernetes.


