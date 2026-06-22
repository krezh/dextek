module "talos" {
  # source = "github.com/krezh/dextek//infrastructure/terraform/modules/talos?ref=main"
  source                 = "../../../../infrastructure/terraform/modules/talos"
  factory_schematic_file = "schematic.yaml"
  matchbox = {
    url         = "http://matchbox.int.plexuz.xyz:8080"
    api         = "matchbox.int.plexuz.xyz:8081"
    host        = "matchbox.int.plexuz.xyz"
    user        = "matchbox"
    private_key = data.infisical_secrets.matchbox.secrets["SSHKEY"].value
    client_cert = data.infisical_secrets.matchbox.secrets["CLIENT_CRT"].value
    client_key  = data.infisical_secrets.matchbox.secrets["CLIENT_KEY"].value
    ca          = data.infisical_secrets.matchbox.secrets["CA_CRT"].value
  }
  template_vars = {
    upsmonHost   = data.infisical_secrets.nut.secrets["HOST"].value
    upsmonPasswd = data.infisical_secrets.nut.secrets["PASSWORD"].value
  }
  bootstrap    = var.bootstrap
  talosconfig  = var.talosconfig
  machine_yaml = var.machine_yaml
}

output "schematic_id" {
  value = module.talos.schematic_id
}

output "get_talos_result" {
  value = module.talos.get_talos_result
}
