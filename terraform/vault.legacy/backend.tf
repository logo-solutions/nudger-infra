terraform {
  backend "local" {
    path = "/root/.terraform/vault/terraform.tfstate"
  }
}
