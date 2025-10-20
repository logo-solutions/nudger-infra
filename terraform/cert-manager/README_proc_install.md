kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.crds.yaml

terraform apply -target=helm_release.cert_manager -auto-approve \
  -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)" \
  -var "dns_zone=logo-solutions.fr" \
  -var "email=loicgourmelon@gmail.com"

Vérif : 
kubectl get all -n cert-manager
kubectl get crds | grep cert-manager

terraform apply -auto-approve \
  -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)" \
  -var "dns_zone=logo-solutions.fr" \
  -var "email=loicgourmelon@gmail.com"
