variable "app_secrets" {
  type        = map(string)
  description = "Map of app name to Infisical folder path"
}

variable "workspace_id" {
  type        = string
  description = "Infisical workspace/project ID"
}

variable "env_slug" {
  type        = string
  description = "Infisical environment slug"
}

data "infisical_secrets" "apps" {
  for_each = var.app_secrets

  env_slug     = var.env_slug
  workspace_id = var.workspace_id
  folder_path  = each.value
}

output "secrets" {
  value       = data.infisical_secrets.apps
  description = "Map of app names to their Infisical secrets"
}
