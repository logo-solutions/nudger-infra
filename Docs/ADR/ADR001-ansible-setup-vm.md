# ADR001 – Ansible pour le setup VM
**Date** : 2025-09-26  
**Statut** : Accepté  

## Contexte
Nous devons préparer une VM (OS, kernel params, container runtime, kubeadm init, réseau CNI).  
Plusieurs approches ont été évaluées :  
- **Scripts shell** (rapide mais difficile à maintenir et tester).  
- **Cloud-init seul** (adapté à la création initiale mais limité pour la maintenance).  
- **Terraform remote-exec** (possible mais peu lisible et fragile).  
- **Ansible** (outillage existant, modules adaptés, idempotence).  

## Décision
Nous choisissons **Ansible** pour le bootstrap système et Kubernetes :  
- installation containerd  
- initialisation kubeadm (control-plane, kube-proxy, flannel)  
- configuration de la VM (swap, sysctl, SSH hardening)  

## Conséquences
- ✅ Lisibilité : chaque étape est décrite sous forme de rôle.  
- ✅ Débogage simple : relancer un rôle/une task suffit.  
- ✅ Idempotence assurée.  
- ❌ Ajoute un outil supplémentaire à côté de Terraform.  
- ❌ Risque de dérive si des modifications manuelles sont faites sur la VM.  

---
