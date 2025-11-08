############### BR FILTER
- name: Ensure br_netfilter module is loaded
  modprobe:
    name: br_netfilter
    state: present

- name: Persist sysctl settings for Kubernetes networking
  copy:
    dest: /etc/sysctl.d/99-kubernetes-network.conf
    content: |
      net.bridge.bridge-nf-call-iptables=1
      net.bridge.bridge-nf-call-ip6tables=1
      net.ipv4.ip_forward=1

- name: Apply sysctl configuration
  command: sysctl --system◊
=======================
 kubescape scan framework nsa
