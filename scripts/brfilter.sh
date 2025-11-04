#!/bin/bash

# SSH into the master node and run commands remotely
ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -i ~/.ssh/hetzner-bastion root@91.98.16.184 << 'EOF'
  # Load the br_netfilter module
  modprobe br_netfilter

  # Set the bridge netfilter sysctl
  echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

  # Apply sysctl settings
  sysctl -p

  # Restart Flannel pod
  kubectl delete pod -n kube-flannel -l app=flannel
EOF
