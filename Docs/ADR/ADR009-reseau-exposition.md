# ADR009 – Architecture réseau et exposition
**Date** : 2025-09-26  
**Statut** : Proposé  

## Contexte
Les services doivent être exposés vers l’extérieur.  
Options :  
- NodePort direct (rapide mais peu scalable).  
- Ingress NGINX en NodePort.  
- LoadBalancer externe (nécessite un provider cloud).  
- Reverse proxy externe.  

## Décision
Nous adoptons **Ingress NGINX en NodePort** avec DNS dynamique (nip.io, ou Cloudflare pour domaines réels).  

## Conséquences
- ✅ Simplicité de mise en place.  
- ✅ Intégration facile avec cert-manager.  
- ❌ Pas de haute dispo (une seule VM).  
- ❌ Limité en montée en charge sans LoadBalancer natif.  

---
