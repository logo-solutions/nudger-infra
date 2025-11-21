helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
sleep 15
k apply -f manifest/ingress.yaml
