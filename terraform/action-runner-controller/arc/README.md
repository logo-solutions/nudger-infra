# Module ARC (GitHub Actions Runner Controller)

Déploie:
- le namespace `arc`
- le secret GitHub App (`github-app-secret`)
- le controller ARC (chart `gha-runner-scale-set-controller`)
- un Runner Scale Set (chart `gha-runner-scale-set`)

## Variables requises

- `github_app_id` : ID de l'app GitHub
- `github_app_installation_id` : Installation ID
- `github_app_private_key` : contenu PEM de la clé
- `github_repo_url` : URL GitHub cible (ex: `https://github.com/logo-solutions/nudger-infra` ou `https://github.com/logo-solutions` pour scope org)

## Exemple

```hcl
module "arc" {
  source = "./modules/arc"

  arc_namespace               = "arc"
  arc_version                 = "0.9.3"

  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  github_app_private_key      = var.github_app_private_key

  github_repo_url             = "https://github.com/logo-solutions/nudger-infra"
  runner_set_name             = "nudger-autoscaling-set"
  min_runners                 = 1
  max_runners                 = 2
}
