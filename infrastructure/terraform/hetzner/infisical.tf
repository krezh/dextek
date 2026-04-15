locals {
  infisical_project_id = "5e13949c-f810-489d-88bd-0749b9474dbb"
  infisical_env        = "default"
}

ephemeral "infisical_secret" "hcloud_token" {
  name         = "HCLOUD_TOKEN"
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Hetzner"
}

ephemeral "infisical_secret" "ssh_private_key" {
  name         = "SSH_PRIVATE_KEY"
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Hetzner"
}

data "infisical_secrets" "pangolin" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Docker/Pangolin"
}
