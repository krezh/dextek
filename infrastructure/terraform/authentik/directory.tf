
data "authentik_group" "superuser" {
  name = "superuser"
}

resource "authentik_group" "downloads" {
  name         = "Downloads"
  is_superuser = false
}

resource "authentik_group" "grafana_admins" {
  name         = "Grafana Admins"
  is_superuser = false
  parent       = data.authentik_group.superuser.id
}

resource "authentik_group" "home" {
  name         = "Home"
  is_superuser = false
}

resource "authentik_group" "infrastructure" {
  name         = "Infrastructure"
  is_superuser = false
}

resource "authentik_group" "monitoring" {
  name         = "Monitoring"
  is_superuser = false
  parent       = resource.authentik_group.grafana_admins.id
}

resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

resource "authentik_group" "mealie_users" {
  name         = "mealie_users"
  is_superuser = false
}

resource "authentik_group" "mealie_admins" {
  name         = "mealie_admins"
  is_superuser = false
  parent       = data.authentik_group.superuser.id
}
