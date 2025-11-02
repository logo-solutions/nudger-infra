
# Installation de Cert-Manager avec Terraform et Helm

## Contexte
L'objectif de cette installation est de déployer **Cert-Manager** sur un cluster Kubernetes afin de gérer les certificats TLS automatiquement via ACME (Let's Encrypt) et d'autres solutions. Cette approche permet d'automatiser la gestion des certificats pour les applications Kubernetes.

## Démarche

L'installation de **Cert-Manager** a été réalisée en utilisant **Terraform** et **Helm** pour assurer un déploiement cohérent et reproductible. Voici les étapes détaillées du processus :

### 1. Application du plan Terraform
La commande suivante a été utilisée pour appliquer les changements :
```bash
terraform apply --auto-approve
```

#### Résultat de l'exécution
- **Namespace `cert-manager`** : Création du namespace `cert-manager` pour organiser les ressources liées à la gestion des certificats.
- **Helm release `cert-manager`** : Installation du chart Helm pour Cert-Manager dans le namespace `cert-manager`.
  - **Configuration** : Les CustomResourceDefinitions (CRDs) ont été installées, et la configuration de **Prometheus** a été désactivée.
  - La version du chart utilisée est **v1.15.1**.

### 2. Détection des changements externes
Lors de l'exécution de Terraform, un message indiquait que des modifications avaient été effectuées en dehors de Terraform, spécifiquement sur le namespace `cert-manager` (qui avait été supprimé manuellement avant l'application de Terraform). Terraform a pris en charge cette modification en recréant le namespace et les ressources nécessaires.

### 3. Création des ressources Kubernetes
Terraform a ensuite procédé à la création des ressources suivantes :
- **Namespace** `cert-manager` : Création du namespace pour organiser les ressources liées à Cert-Manager.
- **Helm release** `cert-manager` : Déploiement de Cert-Manager avec la configuration appropriée.

### 4. Vérification de l'installation
Pour vérifier l'état du déploiement, les commandes suivantes ont été utilisées :
```bash
kubectl get ns
kubectl get all -n cert-manager
```

#### Résultats
- Le **Pod** `cert-manager`, ainsi que les **Pods** associés (`cert-manager-cainjector` et `cert-manager-webhook`), sont tous en état **Running**, ce qui confirme que Cert-Manager est opérationnel.
- Les **Deployments** et les **ReplicaSets** associés ont été créés et sont en fonctionnement, garantissant la haute disponibilité des composants de Cert-Manager.

### 5. Bilan
- **Terraform** a permis de gérer l'installation de **Cert-Manager** via **Helm** de manière **automatisée et sécurisée**, garantissant une installation cohérente et reproductible à chaque fois.
- **Cert-Manager** est maintenant prêt à être utilisé pour gérer les certificats TLS dans le cluster Kubernetes.
- Cette démarche simplifie la gestion des certificats, avec la possibilité de les renouveler automatiquement via **ACME** (Let's Encrypt) ou d'autres solutions.

## Conclusion
Cette installation a permis d'automatiser le déploiement de **Cert-Manager** via **Terraform** et **Helm**, avec une gestion centralisée des certificats TLS. Le processus a été fluide, rapide, et facilement reproductible dans différents environnements Kubernetes.


