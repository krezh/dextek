locals {
  oidc_migration_apps = {
    radarr           = "Radarr"
    sonarr           = "Sonarr"
    prowlarr         = "Prowlarr"
    bazarr           = "Bazarr"
    sabnzbd          = "SABnzbd"
    maintainerr      = "Maintainerr"
    pinchflat        = "Pinchflat"
    changedetection  = "Changedetection"
    "home-assistant" = "HomeAssistant"
    librespeed       = "Librespeed"
  }

  # Only apps whose Infisical folder doesn't exist yet. The rest use a literal
  # folder_path below, kept out of Terraform's create/destroy lifecycle.
  oidc_missing_folders = toset(["home-assistant", "librespeed", "pinchflat"])
}

resource "infisical_secret_folder" "oidc_app" {
  for_each         = local.oidc_missing_folders
  name             = local.oidc_migration_apps[each.key]
  folder_path      = "/Kubernetes/DexTek"
  environment_slug = local.infisical_env
  project_id       = local.infisical_project_id
}

resource "infisical_secret" "oidc_client_secret" {
  for_each         = local.oidc_migration_apps
  name             = "OIDC_CLIENT_SECRET"
  env_slug         = local.infisical_env
  workspace_id     = local.infisical_project_id
  folder_path = contains(local.oidc_missing_folders, each.key) ? (
    infisical_secret_folder.oidc_app[each.key].path
  ) : "/Kubernetes/DexTek/${each.value}"
  value_wo         = module.oauth_apps.oauth2_client_secrets[each.key]
  value_wo_version = 1
}
