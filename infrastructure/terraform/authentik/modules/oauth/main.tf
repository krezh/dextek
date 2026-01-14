terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0"
    }
  }
}

locals {
  meta_icon = {
    for k, app in var.oauth_apps :
    k => (
      app.meta_icon == "dashboard-icons" ?
      "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/${lower(app.slug)}.png" :
      app.meta_icon != null && app.meta_icon != "" ?
      app.meta_icon :
      ""
    )
  }
  redirect_uris = {
    for k, app in var.oauth_apps : k => [
      for uri in app.redirect_uris : {
        matching_mode = "strict"
        url           = uri
      }
    ]
  }
}

variable "oauth_apps" {
  description = "Map of OIDC apps and their configuration"
  type = map(object({
    name                   = string
    slug                   = string
    app_domain             = string
    app_group              = optional(string, null)
    access_groups          = optional(set(string), null)
    policy_engine_mode     = optional(string, "any")
    authorization_flow_id  = string
    authentication_flow_id = string
    invalidation_flow_id   = string
    meta_icon              = optional(string, null)
    meta_description       = optional(string, null)
    meta_launch_url        = optional(string, null)
    open_in_new_tab        = optional(bool, false)
    access_token_validity  = optional(string, "hours=4")
    refresh_token_validity = optional(string, "weeks=52")
    client_id              = string
    client_secret          = string
    signing_key_id         = optional(string, null)
    client_type            = optional(string, "confidential")
    redirect_uris          = list(string)
    property_mappings      = optional(list(string), [])
  }))
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_provider_oauth2" "main" {
  for_each               = var.oauth_apps
  name                   = each.value.name
  client_id              = each.value.client_id
  client_type            = each.value.client_type
  client_secret          = each.value.client_secret
  authorization_flow     = each.value.authorization_flow_id
  authentication_flow    = each.value.authentication_flow_id
  invalidation_flow      = each.value.invalidation_flow_id
  access_token_validity  = each.value.access_token_validity
  refresh_token_validity = each.value.refresh_token_validity
  property_mappings      = each.value.property_mappings
  allowed_redirect_uris  = local.redirect_uris[each.key]
  signing_key            = coalesce(each.value.signing_key_id, data.authentik_certificate_key_pair.generated.id)
  lifecycle {
    ignore_changes = [
      signing_key
    ]
  }
}

resource "authentik_application" "main" {
  for_each           = var.oauth_apps
  name               = title(each.value.name)
  slug               = each.value.slug
  group              = each.value.app_group
  open_in_new_tab    = each.value.open_in_new_tab
  policy_engine_mode = each.value.policy_engine_mode
  meta_launch_url    = coalesce(each.value.meta_launch_url, "https://${each.value.app_domain}")
  meta_icon          = local.meta_icon[each.key]
  meta_description   = each.value.meta_description
  protocol_provider  = authentik_provider_oauth2.main[each.key].id
}

resource "authentik_policy_binding" "app_access" {
  for_each = {
    for pair in flatten([
      for app_key, app in var.oauth_apps : [
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

output "application_ids" {
  value = { for k, app in authentik_application.main : k => app.uuid }
}
output "oauth2_provider_ids" {
  value = { for k, provider in authentik_provider_oauth2.main : k => provider.id }
}
