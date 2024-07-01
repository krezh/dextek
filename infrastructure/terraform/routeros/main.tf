data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

data "doppler_secrets" "prd_routeros" {}

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
  password   = data.doppler_secrets.prd_routeros.map.MIKROTIK_EXPORTER
  comment    = var.comment
}
