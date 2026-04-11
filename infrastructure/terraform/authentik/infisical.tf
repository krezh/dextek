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

data "infisical_secrets" "grafana" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Grafana"
}

data "infisical_secrets" "mealie" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Mealie"
}

data "infisical_secrets" "immich" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Immich"
}

data "infisical_secrets" "zipline" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Zipline"
}

data "infisical_secrets" "kubernetes" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Kubernetes"
}

data "infisical_secrets" "karakeep" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Karakeep"
}

data "infisical_secrets" "wakapi" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Wakapi"
}

data "infisical_secrets" "plex" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Plex"
}

data "infisical_secrets" "pangolin" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Authentik/Pangolin"
}
