locals {
  infisical_project_id = "5e13949c-f810-489d-88bd-0749b9474dbb"
  infisical_env        = "default"
}

data "infisical_secrets" "nut" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Talos/Nut"
}

data "infisical_secrets" "matchbox" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Talos/Matchbox"
}
