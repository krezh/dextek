terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
  }
}

variable "name" {
  type = string
}
variable "slug" {
  type    = string
  default = null
}
variable "domain" {
  type = string
}
variable "access_token_validity" {
  type    = string
  default = "weeks=8"
}
variable "refresh_token_validity" {
  type    = string
  default = "weeks=52"
}
variable "authorization_flow_id" {
  type = string
}
variable "authentication_flow_id" {
  type = string
}

variable "invalidation_flow_id" {
  type = string
}

variable "access_groups" {
  type    = set(string)
  default = null
}

variable "meta_icon" {
  type    = string
  default = null
}
variable "meta_description" {
  type    = string
  default = null
}
variable "meta_launch_url" {
  type    = string
  default = null
}
variable "open_in_new_tab" {
  type    = bool
  default = false
}
variable "app_group" {
  type    = string
  default = null
}
variable "policy_engine_mode" {
  type    = string
  default = "any"
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "signing_key_id" {
  type    = string
  default = null
}

variable "client_type" {
  type    = string
  default = "confidential"
}
variable "redirect_uris" {
  type = list(string)
}
locals {
  redirect_uris = [for uri in var.redirect_uris : {
    matching_mode = "strict",
    url           = uri,
  }]
}

variable "property_mappings" {
  type    = list(string)
  default = null
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_provider_oauth2" "main" {
  name                   = var.name
  client_id              = var.client_id
  client_type            = var.client_type
  client_secret          = var.client_secret
  authorization_flow     = var.authorization_flow_id
  authentication_flow    = var.authentication_flow_id
  invalidation_flow      = var.invalidation_flow_id
  access_token_validity  = var.access_token_validity
  refresh_token_validity = var.refresh_token_validity
  property_mappings      = var.property_mappings
  allowed_redirect_uris  = local.redirect_uris
  signing_key            = coalesce(var.signing_key_id, data.authentik_certificate_key_pair.generated.id)
  lifecycle {
    ignore_changes = [
      signing_key
    ]
  }
}

resource "authentik_application" "main" {
  name               = title(var.name)
  slug               = coalesce(var.slug, var.name)
  group              = var.app_group
  open_in_new_tab    = var.open_in_new_tab
  policy_engine_mode = var.policy_engine_mode
  meta_launch_url    = coalesce(var.meta_launch_url, "https://${var.domain}")
  meta_icon          = var.meta_icon
  meta_description   = var.meta_description
  protocol_provider  = authentik_provider_oauth2.main.id
}

resource "authentik_policy_binding" "app-access" {
  for_each = var.access_groups != null ? { for group in var.access_groups : group => group } : {}
  target   = authentik_application.main.uuid
  group    = each.value
  order    = 0
}

output "application_id" {
  value = authentik_application.main.uuid
}
output "oauth2_provider_id" {
  value = authentik_provider_oauth2.main.id
}
