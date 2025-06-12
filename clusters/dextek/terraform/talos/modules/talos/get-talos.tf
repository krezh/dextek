resource "ssh_resource" "get_talos" {
  #triggers = {
  #  always_run = "${timestamp()}"
  #}
  host        = var.matchbox.host
  user        = var.matchbox.user
  agent       = false
  private_key = var.matchbox.private_key

  when = "create" # Default

  file {
    source      = "${path.module}/scripts/get-factory-talos.sh"
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
