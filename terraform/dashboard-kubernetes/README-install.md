sudo ufw allow 30443/tcp
sudo ufw allow 30080/tcp
kubectl -n kubernetes-dashboard create token kubernetes-dashboard-admin
