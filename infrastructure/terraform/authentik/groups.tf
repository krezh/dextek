data "authentik_group" "superuser" {
  name = "superuser"
}

locals {
  groups = toset([
    "grafana-admins",
    "users",
    "mealie_users",
    "mealie_admins",
    "jellyfin-users",
    "jellyfin-admins",
    "ldap-admins",
    "kube-admins"
  ])
}

resource "authentik_group" "groups" {
  for_each = local.groups

  name         = each.value
  is_superuser = false
}
