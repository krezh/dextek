variable "domain" {
  type = object({
    internal = string
    external = string
  })
  description = "Internal and external domain names"
}

variable "bind_flow_id" {
  type        = string
  description = "Flow used for LDAP bind operations"
}

variable "unbind_flow_id" {
  type        = string
  description = "Flow used for LDAP unbind operations"
}

variable "service_connection_id" {
  type        = string
  description = "Kubernetes service connection for LDAP outpost"
}

variable "certificate_id" {
  type        = string
  description = "Certificate for LDAP TLS"
}

variable "ldap_apps" {
  type = map(object({
    app_group        = optional(string, "")
    access_groups    = list(string)
    meta_icon        = optional(string, "")
    meta_description = optional(string, "")
    meta_launch_url  = optional(string, "")
  }))
  description = "Map of LDAP applications to create"
}

locals {
  # LDAP apps are always internal
  app_launch_urls = {
    for k, app in var.ldap_apps :
    k => coalesce(app.meta_launch_url, "https://${k}.${var.domain.external}")
  }
}

# Single shared LDAP provider
resource "authentik_provider_ldap" "ldap" {
  name            = "LDAP"
  base_dn         = "DC=ldap,DC=dextek,DC=io"
  bind_flow       = var.bind_flow_id
  unbind_flow     = var.unbind_flow_id
  mfa_support     = false
  certificate     = var.certificate_id
  tls_server_name = "ldap-lb.${var.domain.internal}"
  search_mode     = "direct"
  bind_mode       = "direct"
}

# Single shared outpost
resource "authentik_outpost" "ldap" {
  name               = "LDAP"
  type               = "ldap"
  service_connection = var.service_connection_id
  protocol_providers = [authentik_provider_ldap.ldap.id]

  config = jsonencode({
    log_level               = "info"
    authentik_host          = "http://authentik-server.auth.svc.cluster.local"
    authentik_host_browser  = "https://sso.${var.domain.external}/"
    refresh_interval        = "minutes=5"
    kubernetes_replicas     = 1
    kubernetes_namespace    = "auth"
    object_naming_template  = "ak-outpost-%(name)s"
    kubernetes_service_type = "LoadBalancer"
    kubernetes_json_patches = {
      service = [{
        op   = "add"
        path = "/metadata/annotations"
        value = {
          "external-dns.alpha.kubernetes.io/hostname" = "ldap-lb.talos.plexuz.xyz"
        }
      }]
    }
  })
}

# Create applications
resource "authentik_application" "apps" {
  for_each = var.ldap_apps

  name              = title(each.key)
  slug              = each.key
  group             = each.value.app_group
  meta_icon         = each.value.meta_icon
  meta_description  = each.value.meta_description
  meta_launch_url   = local.app_launch_urls[each.key]
  protocol_provider = authentik_provider_ldap.ldap.id
}

# Create policy bindings for each app
resource "authentik_policy_binding" "app_access" {
  for_each = merge([
    for app_key, app in var.ldap_apps : {
      for idx, group in app.access_groups :
      "${app_key}::${group}" => {
        app_uuid = authentik_application.apps[app_key].uuid
        group_id = group
      }
    }
  ]...)

  target = each.value.app_uuid
  group  = each.value.group_id
  order  = 0
}
