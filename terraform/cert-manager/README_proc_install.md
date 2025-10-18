terraform apply -target=helm_release.cert_manager -auto-approve \
  -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)" \
  -var "dns_zone=logo-solutions.fr" \
  -var "email=loicgourmelon@gmail.com"


terraform apply -auto-approve \
  -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)" \
  -var "dns_zone=logo-solutions.fr" \
  -var "email=loicgourmelon@gmail.com"
