export TF_VAR_github_app_id="$(bw get item ARC_APP_ID | jq -r .login.username)"
export TF_VAR_github_app_installation_id="$(bw get item ARC_APP_INSTALL | jq -r .login.username)"
export TF_VAR_github_app_private_key="$(bw get item ARC_APP_KEY | jq -r .notes)"
