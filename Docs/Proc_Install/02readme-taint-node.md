kubectl taint nodes master1 node-role.kubernetes.io/control-plane:NoSchedule-
terraform apply -target=helm_release.cert_manager
terraform apply
--------AA
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
