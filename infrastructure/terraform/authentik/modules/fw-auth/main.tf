terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.10.0"
    }
  }
}

variable "forward_auth_apps" {
  description = "Map of forward auth apps and their configuration"
  type = map(object({
    app_name                = string
    slug                    = string
    app_domain              = string
    app_group               = string
    access_groups           = set(string)
    policy_engine_mode      = string
    authorization_flow_uuid = string
    invalidation_flow_uuid  = string
    meta_icon               = string
    outpost                 = string
  }))
}

locals {
  domains = { for k, app in var.forward_auth_apps : k => join(".", slice(split(".", app.app_domain), length(split(".", app.app_domain)) - 2, length(split(".", app.app_domain)))) }
  internal_proxy_provider_ids = [
    for k, app in var.forward_auth_apps : authentik_provider_proxy.main[k].id
    if app.outpost == "internal"
  ]
  external_proxy_provider_ids = [
    for k, app in var.forward_auth_apps : authentik_provider_proxy.main[k].id
    if app.outpost == "external"
  ]
}

resource "authentik_provider_proxy" "main" {
  for_each                      = var.forward_auth_apps
  name                          = each.value.app_name
  external_host                 = "https://${each.value.app_domain}"
  internal_host                 = null
  cookie_domain                 = local.domains[each.key]
  basic_auth_enabled            = false
  basic_auth_password_attribute = null
  basic_auth_username_attribute = null
  mode                          = "forward_single"
  authentication_flow           = null
  authorization_flow            = each.value.authorization_flow_uuid
  invalidation_flow             = each.value.invalidation_flow_uuid
  access_token_validity         = "days=10"
  refresh_token_validity        = "days=30"
  property_mappings             = []
  skip_path_regex               = null
  jwt_federation_providers      = []
}

resource "authentik_application" "main" {
  for_each           = var.forward_auth_apps
  name               = title(each.value.app_name)
  slug               = each.value.slug
  protocol_provider  = authentik_provider_proxy.main[each.key].id
  group              = each.value.app_group
  open_in_new_tab    = false
  meta_icon          = each.value.meta_icon
  meta_launch_url    = null
  policy_engine_mode = each.value.policy_engine_mode
}

resource "authentik_policy_binding" "app_access" {
  for_each = {
    for pair in flatten([
      for app_key, app in var.forward_auth_apps : [
        for group in app.access_groups : {
          app_key = app_key
          group   = group
        }
      ]
    ]) : "${pair.app_key}::${pair.group}" => pair
  }

  target = authentik_application.main[each.value.app_key].uuid
  group  = each.value.group
  order  = 0
}

output "internal_proxy_provider_ids" {
  value = local.internal_proxy_provider_ids
}
output "external_proxy_provider_ids" {
  value = local.external_proxy_provider_ids
}
