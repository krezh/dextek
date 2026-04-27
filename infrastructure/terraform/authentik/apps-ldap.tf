module "ldap_apps" {
  source = "./modules/ldap"

  domain                = var.domain
  bind_flow_id          = authentik_flow.authentication.uuid
  unbind_flow_id        = data.authentik_flow.default-provider-invalidation-flow.id
  service_connection_id = authentik_service_connection_kubernetes.local.id
  certificate_id        = data.authentik_certificate_key_pair.generated.id

  ldap_apps = {
    jellyfin = {
      app_group = "Media"
      access_groups = [
        authentik_group.groups["jellyfin-users"].id,
        authentik_group.groups["jellyfin-admins"].id
      ]
      meta_icon        = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jellyfin.png"
      meta_description = "Requests: https://requests.${var.domain["external"]}"
      meta_launch_url  = "https://jellyfin.${var.domain["external"]}"
    }
  }
}
