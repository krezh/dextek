data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

data "doppler_secrets" "prd_routeros" {}

resource "routeros_system_identity" "identity" {
  name = "yggdrasil"
}

resource "routeros_system_user_group" "prometheus_exporter" {
  name   = "prometheus_exporter"
  policy = ["api", "!ftp", "!local", "!password", "!policy", "read", "!reboot", "!rest-api", "!romon", "!sensitive", "!sniff", "!ssh", "!telnet", "!test", "!web", "!winbox", "!write"]
}

resource "routeros_system_user" "prometheus_exporter" {
  depends_on = [routeros_system_user_group.prometheus_exporter]
  name       = "prometheus_exporter"
  address    = "0.0.0.0/0"
  group      = "prometheus_exporter"
  password   = data.doppler_secrets.prd_routeros.map.PROMETHEUS_EXPORTER
  comment    = var.comment
}
