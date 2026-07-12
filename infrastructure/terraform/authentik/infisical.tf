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
  folder_path  = "/Kubernetes/DexTek/Grafana"
}

data "infisical_secrets" "mealie" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Mealie"
}

data "infisical_secrets" "immich" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Immich"
}

data "infisical_secrets" "zipline" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Zipline"
}

data "infisical_secrets" "kubernetes" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Kubernetes"
}

data "infisical_secrets" "miniflux" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Miniflux"
}

data "infisical_secrets" "termix" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Termix"
}

data "infisical_secrets" "profilarr" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Profilarr"
}

data "infisical_secrets" "papra" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Papra"
}

data "infisical_secrets" "qui" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Kubernetes/DexTek/Qui"
}
