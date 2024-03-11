resource "ssh_resource" "get_talos" {
  #triggers = {
  #  always_run = "${timestamp()}"
  #}
  host        = "rpi02.usr.int.plexuz.xyz"
  user        = "matchbox"
  agent       = false
  private_key = data.sops_file.secrets.data["matchbox.sshkey"]

  when = "create" # Default

  file {
    source      = "scripts/get-factory-talos.sh"
    destination = "/var/lib/matchbox/assets/get-factory-talos.sh"
    permissions = "0700"
  }

  commands = [
    "cd /var/lib/matchbox/assets/ && ./get-factory-talos.sh -v ${var.talos_version} -h ${local.talos_factory_id}"
  ]
}

output "get_talos_result" {
  value = try(ssh_resource.get_talos.result)
}
