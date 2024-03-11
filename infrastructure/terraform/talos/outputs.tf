resource "local_sensitive_file" "talosconfig" {
  count           = var.talosconfig == true ? 1 : 0
  filename        = "talosconfig"
  content         = data.talos_client_configuration.talosconfig.talos_config
  file_permission = 0600
}

resource "local_sensitive_file" "machine_config" {
  for_each = var.machine_yaml ? var.nodes : {}

  filename        = "${each.value.type}_${each.value.hostname}.yaml"
  content         = data.talos_machine_configuration.machine[each.key].machine_configuration
  file_permission = 0600
}

# resource "local_sensitive_file" "worker_config" {
#   for_each = var.worker_yaml ? var.nodes.workers : {}
# 
#   filename        = "worker_${each.value.hostname}.yaml"
#   content         = data.talos_machine_configuration.worker[each.key].machine_configuration
#   file_permission = 0600
# }
