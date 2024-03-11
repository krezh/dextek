data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

data "doppler_secrets" "prd_routeros" {}

resource "routeros_system_identity" "identity" {
  name = "yggdrasil"
}
