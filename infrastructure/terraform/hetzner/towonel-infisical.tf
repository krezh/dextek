resource "random_bytes" "towonel_invite_hash_key" {
  length = 32
}

resource "infisical_secret" "towonel_invite_hash_key" {
  name         = "TOWONEL_INVITE_HASH_KEY"
  value        = random_bytes.towonel_invite_hash_key.hex
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Towonel"
}

data "infisical_secrets" "towonel" {
  env_slug     = local.infisical_env
  workspace_id = local.infisical_project_id
  folder_path  = "/Terraform/Towonel"

  depends_on = [infisical_secret.towonel_invite_hash_key]
}
