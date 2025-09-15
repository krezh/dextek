resource "authentik_user" "ldap_bind" {
  username = "ldap_bind"
  type     = "service_account"
  groups   = [authentik_group.jellyfin-users.id]
}
