
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
}

resource "authentik_group" "jellyfin-users" {
  name         = "jellyfin-users"
  is_superuser = false
}

resource "authentik_group" "jellyfin-admins" {
  name         = "jellyfin-admins"
  is_superuser = false
}

resource "authentik_group" "ldap-admins" {
  name         = "ldap-admins"
  is_superuser = false
}

resource "authentik_group" "forgejo_users" {
  name         = "forgejo_users"
  is_superuser = false
}

resource "authentik_group" "forgejo_admins" {
  name         = "forgejo_admins"
  is_superuser = false
}
