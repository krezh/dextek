resource "routeros_system_identity" "identity" {
  name = "yggdrasil"
}

resource "routeros_system_user_group" "mikrotik-exporter" {
  name   = "mikrotik-exporter"
  policy = ["api", "!ftp", "!local", "!password", "!policy", "read", "!reboot", "!rest-api", "!romon", "!sensitive", "!sniff", "!ssh", "!telnet", "!test", "!web", "!winbox", "!write"]
}

resource "routeros_system_user" "mikrotik-exporter" {
  depends_on = [routeros_system_user_group.mikrotik-exporter]
  name       = "mikrotik-exporter"
  group      = "mikrotik-exporter"
  password   = data.infisical_secrets.routeros.secrets["MIKROTIK_EXPORTER"].value
  comment    = var.comment
}

resource "routeros_ip_neighbor_discovery_settings" "disable" {
  discover_interface_list = "none"
}
