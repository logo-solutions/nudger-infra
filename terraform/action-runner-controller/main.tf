module "arc" {
  source = "./arc"

  arc_namespace               = var.arc_namespace
  arc_version                 = var.arc_version
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  github_app_private_key      = var.github_app_private_key
  github_repo_url             = var.github_repo_url
  runner_scale_set_name       = var.runner_scale_set_name
  min_runners                 = var.min_runners
  max_runners                 = var.max_runners
}
