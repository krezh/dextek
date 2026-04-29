data "authentik_group" "superuser" {
  name = "superuser"
}

locals {
  groups = toset([
    "Downloads",
    "Grafana Admins",
    "Home",
    "Infrastructure",
    "Monitoring",
    "users",
    "mealie_users",
    "mealie_admins",
    "jellyfin-users",
    "jellyfin-admins",
    "ldap-admins",
  ])
}

resource "authentik_group" "groups" {
  for_each = local.groups

  name         = each.value
  is_superuser = false
}
