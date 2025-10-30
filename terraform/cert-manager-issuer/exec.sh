terraform init -upgrade
terraform apply -auto-approve \
  -var "email=loicgourmelon@gmail.com" \
  -var "dns_zone=logo-solutions.fr" \
  -var "cloudflare_api_token=$(bw get item token_cloudflare | jq -r .login.password)"
