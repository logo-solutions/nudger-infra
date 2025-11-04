# 🧾 ADR009 – Architecture réseau et exposition

**Date :** 2025-09-26  
**Statut :** 🟢 Adopté (mis à jour)

---

## 🎯 Contexte

Les services du cluster Kubernetes doivent être exposés de manière sécurisée et stable vers l’extérieur.  
Deux approches sont possibles :  

1. **LoadBalancer fourni par le provider cloud** (solution managée).  
2. **Exposition auto-gérée** via **Ingress NGINX en NodePort** ou **MetalLB**.

Le choix dépend de la taille du cluster, du budget et de la philosophie d’infrastructure (cloud managé vs auto-hébergé).

---

## ⚙️ Option 1 – LoadBalancer du Provider Cloud

### Description
Les grands providers (AWS, GCP, OVH, Hetzner Cloud, etc.) proposent des LoadBalancers intégrés, activés automatiquement dès qu’un `Service type=LoadBalancer` est déployé.  
L’adresse publique et le routage sont gérés par le cloud provider, qui distribue le trafic vers les nœuds du cluster.

### Avantages
- ✅ **Haute disponibilité native** (répartition automatique entre plusieurs nœuds).  
- ✅ **IP publique fixe et managée**.  
- ✅ **Maintenance et monitoring inclus** côté provider.  
- ✅ **Compatibilité directe** avec Kubernetes (`type: LoadBalancer`).  

### Inconvénients
- ❌ **Dépendance au provider cloud** (API propriétaire).  
- ❌ **Coût récurrent** (souvent facturé à l’heure et au trafic).  
- ❌ **Complexité réseau accrue** (si multi-cloud ou local).  
- ❌ **Moins de contrôle** sur la configuration interne (timeouts, ports, TLS).

---

## ⚙️ Option 2 – Exposition auto-gérée (Ingress NGINX en NodePort ou MetalLB)

### Description
Dans une infrastructure auto-hébergée (ex. Hetzner VPS, cluster bare metal), aucun LoadBalancer cloud n’est disponible.  
Deux solutions open source permettent d’exposer les services :  

#### a) **Ingress NGINX en NodePort**
- L’Ingress Controller (NGINX) est exposé sur un port fixe (`30080` pour HTTP, `30443` pour HTTPS).  
- Le DNS (Cloudflare ou nip.io) pointe directement sur l’IP publique du nœud maître ou du bastion.  

#### b) **MetalLB**
- Ajoute un “LoadBalancer logiciel” à Kubernetes.  
- Distribue une IP virtuelle entre plusieurs nœuds.  
- Les Services `type=LoadBalancer` deviennent compatibles sans cloud externe.  

### Avantages
- ✅ **Aucune dépendance cloud**, 100 % open source.  
- ✅ **Contrôle total** sur l’architecture réseau.  
- ✅ **Compatible avec cert-manager** (ACME DNS-01 / HTTP-01).  
- ✅ **Économique** : pas de coût de LoadBalancer managé.  

### Inconvénients
- ❌ **Haute disponibilité limitée** (NodePort sur un seul nœud).  
- ❌ **Maintenance réseau manuelle** (firewall, DNS, redondance).  
- ❌ **MetalLB** requiert une configuration L2/L3 précise pour la redondance.  

---

## 🧭 Décision

Nous adoptons une approche **auto-gérée** cohérente avec la philosophie d’infrastructure actuelle (Hetzner + Cloudflare) :

- **Ingress NGINX** exposé en **NodePort (30443)**.  
- **DNS dynamique** via **Cloudflare** pour les domaines réels (ACME DNS-01).  
- **Cert-manager** pour la gestion automatique des certificats TLS.  
- **Pas de dépendance cloud provider**.  

Une évolution vers **MetalLB** est envisagée à moyen terme pour offrir une IP virtuelle redondante entre plusieurs nœuds.

---

## ⚙️ Conséquences

### ✅ Avantages
- Simplicité de mise en place (un seul bastion ou master).  
- Intégration directe avec cert-manager et DNS Cloudflare.  
- Pas de coût additionnel lié à un LoadBalancer managé.  
- Infrastructure portable sur n’importe quel cloud ou bare-metal.  

### ⚠️ Inconvénients
- Pas de haute disponibilité native (si le nœud tombe, le service devient indisponible).  
- Scalabilité limitée sans MetalLB ou LoadBalancer matériel.  
- Configuration réseau (ports, firewall) à maintenir manuellement.  

---

## 🧩 Synthèse des options

| Critère | LoadBalancer Provider | Ingress NodePort / MetalLB |
|----------|----------------------|-----------------------------|
| **HA & Scalabilité** | ✅ Native | ⚠️ Limitée (ou manuelle avec MetalLB) |
| **Dépendance externe** | ❌ Forte (API provider) | ✅ Aucune |
| **Coût** | 💰 Récurent | 💸 Gratuit |
| **Simplicité** | ✅ Automatique | ⚙️ Configuration manuelle |
| **Compatibilité Kubernetes** | ✅ Native | ✅ Compatible |
| **TLS & DNS (cert-manager)** | ✅ Intégré | ✅ Compatible Cloudflare |

---

**Rédacteur :** Loïc Bourmelon  
**Revu par :** Thomas Toussaint  
**Dernière mise à jour :** 2025-11-04

