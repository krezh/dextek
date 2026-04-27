# Infisical secrets

locals {
  infisical_project_id = "5e13949c-f810-489d-88bd-0749b9474dbb"
  infisical_env        = "default"
}

ephemeral "infisical_secret" "authentik_token" {
  name         = "AUTHENTIK_TOKEN"
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Authentik"
}

module "app_secrets" {
  source = "./modules/infisical-app"

  workspace_id = local.infisical_project_id
  env_slug     = local.infisical_env

  app_secrets = {
    grafana    = "/Kubernetes/DexTek/Grafana"
    mealie     = "/Kubernetes/DexTek/Mealie"
    immich     = "/Kubernetes/DexTek/Immich"
    zipline    = "/Kubernetes/DexTek/Zipline"
    kubernetes = "/Kubernetes/DexTek/Kubernetes"
    miniflux   = "/Kubernetes/DexTek/Miniflux"
  }
}
