terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.2.0"
    }
  }
}

locals {
  app_domains = {
    for k, app in var.oauth_apps :
    k => coalesce(app.app_domain, "${k}.${app.external ? var.domain.external : var.domain.internal}")
  }
  meta_icon = {
    for k, app in var.oauth_apps :
    k => (
      app.meta_icon == "dashboard-icons" ?
      "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/${lower(k)}.svg" :
      app.meta_icon != null && app.meta_icon != "" ?
      app.meta_icon :
      ""
    )
  }
  redirect_uris = {
    for k, app in var.oauth_apps : k => concat(
      [for path in app.redirect_uri_paths : {
        matching_mode = "strict"
        url           = "https://${local.app_domains[k]}${path}"
      }],
      [for uri in app.redirect_uris : {
        matching_mode = "strict"
        url           = uri
      }]
    )
  }
}

variable "domain" {
  description = "Internal and external domain names"
  type = object({
    internal = string
    external = string
  })
}

variable "authorization_flow_id" {
  description = "Default flow used for authorization"
  type        = string
}

variable "authentication_flow_id" {
  description = "Default flow used for authentication"
  type        = string
}

variable "invalidation_flow_id" {
  description = "Default flow used on logout"
  type        = string
}

variable "property_mappings" {
  description = "Default OIDC scope/claim mappings applied to all apps"
  type        = list(string)
}

variable "oauth_apps" {
  description = "Map of OIDC apps and their configuration"
  type = map(object({
    name                   = optional(string, null)           # Display name; defaults to title-cased map key
    slug                   = optional(string, null)           # URL slug; defaults to map key
    external               = optional(bool, false)            # Use external domain instead of internal
    app_domain             = optional(string, null)           # Override derived domain
    app_group              = optional(string, null)           # Authentik app group label
    access_groups          = optional(set(string), null)      # Groups allowed to access the app
    policy_engine_mode     = optional(string, "any")          # Policy evaluation mode: any or all
    authorization_flow_id  = optional(string, null)           # Overrides root authorization_flow_id
    authentication_flow_id = optional(string, null)           # Overrides root authentication_flow_id
    invalidation_flow_id   = optional(string, null)           # Overrides root invalidation_flow_id
    meta_icon              = optional(string, "dashboard-icons") # Icon URL or "dashboard-icons" to auto-resolve
    meta_description       = optional(string, null)           # Short app description shown in the portal
    meta_launch_url        = optional(string, null)           # Override launch URL; defaults to app domain
    open_in_new_tab        = optional(bool, false)            # Open app in a new browser tab
    access_token_validity  = optional(string, "hours=4")      # Access token lifetime
    refresh_token_validity = optional(string, "weeks=52")     # Refresh token lifetime
    client_id              = string                           # OAuth2 client ID
    client_secret          = string                           # OAuth2 client secret
    signing_key_id         = optional(string, null)           # Signing key; defaults to self-signed cert
    client_type            = optional(string, "confidential") # confidential or public
    redirect_uri_paths     = optional(list(string), [])       # Paths appended to app domain as redirect URIs
    redirect_uris          = optional(list(string), [])       # Explicit redirect URIs (merged with paths)
    property_mappings      = optional(list(string), null)     # Overrides root property_mappings
  }))
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate 2"
}

resource "authentik_provider_oauth2" "main" {
  for_each               = var.oauth_apps
  name                   = coalesce(each.value.name, title(each.key))
  client_id              = each.value.client_id
  client_type            = each.value.client_type
  client_secret          = each.value.client_secret
  authorization_flow     = coalesce(each.value.authorization_flow_id, var.authorization_flow_id)
  authentication_flow    = coalesce(each.value.authentication_flow_id, var.authentication_flow_id)
  invalidation_flow      = coalesce(each.value.invalidation_flow_id, var.invalidation_flow_id)
  access_token_validity  = each.value.access_token_validity
  refresh_token_validity = each.value.refresh_token_validity
  property_mappings      = coalesce(each.value.property_mappings, var.property_mappings)
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
  name               = title(coalesce(each.value.name, each.key))
  slug               = coalesce(each.value.slug, each.key)
  group              = each.value.app_group
  open_in_new_tab    = each.value.open_in_new_tab
  policy_engine_mode = each.value.policy_engine_mode
  meta_launch_url    = coalesce(each.value.meta_launch_url, "https://${local.app_domains[each.key]}")
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

output "app_keys" {
  value       = keys(var.oauth_apps)
  description = "List of OAuth app keys"
}
