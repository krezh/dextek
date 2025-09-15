resource "authentik_provider_ldap" "ldap" {
  name        = "LDAP"
  base_dn     = "DC=ldap,DC=dextek,DC=io" ## This doesnt matter for authentik
  bind_flow   = authentik_flow.authentication.uuid
  unbind_flow = data.authentik_flow.default-provider-invalidation-flow.id
  mfa_support = false
  # certificate     = data.authentik_certificate_key_pair.main.id
  # tls_server_name = "ldap.${var.domain["external"]}"
}

resource "authentik_outpost" "LDAP" {
  name               = "LDAP"
  type               = "ldap"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [authentik_provider_ldap.ldap.id]
  config = jsonencode({
    "log_level" : "info"
    "authentik_host" : "https://sso.${var.domain["external"]}/"
    "refresh_interval" : "minutes=5"
    "kubernetes_replicas" : 1
    "kubernetes_namespace" : "auth"
    "object_naming_template" : "ak-outpost-%(name)s"
    "kubernetes_service_type" : "LoadBalancer"
    "kubernetes_json_patches" : {
      "service" : [
        {
          "op" : "add",
          "path" : "/metadata/annotations",
          "value" : {
            "coredns.io/hostname" : "ldap-lb"
          }
        }
      ]
    }
  })
}

resource "authentik_application" "jellyfin" {
  name              = "Jellyfin"
  slug              = "jellyfin"
  meta_icon         = ""
  meta_description  = "My Streaming Service - To Request Stuff https://requests.${var.domain["external"]}"
  meta_launch_url   = "https://jellyfin.${var.domain["external"]}/"
  protocol_provider = authentik_provider_ldap.ldap.id
}

resource "authentik_policy_binding" "jellyfin-group-access" {
  target = authentik_application.jellyfin.uuid
  group  = authentik_group.jellyfin-users.id
  order  = 0
}

resource "authentik_policy_binding" "jellyfin-admins-group-access" {
  target = authentik_application.jellyfin.uuid
  group  = authentik_group.jellyfin-admins.id
  order  = 0
}
