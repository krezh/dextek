resource "talos_machine_secrets" "talos" {
  lifecycle {
    prevent_destroy = true
  }
}

data "talos_machine_configuration" "machine" {
  for_each = var.nodes
  depends_on = [
    talos_machine_secrets.talos
  ]
  machine_type     = each.value.type
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint

  machine_secrets = talos_machine_secrets.talos.machine_secrets
  config_patches = [
    templatefile("talosPatches/config-patch.yaml", {
      talos_version      = var.talos_version,
      talos_factory_hash = local.talos_factory_id,
      zot_factory_url    = var.zot_factory_url,
      upsmonHost         = data.sops_file.secrets.data["nut.host"],
      upsmonPasswd       = data.sops_file.secrets.data["nut.password"],
      hostname           = each.key,
      disk_model         = each.value.disk_model,
      mac_addr           = each.value.mac_addr,
      vip                = var.vip,
      driver             = each.value.driver,
      driver_10g         = each.value.driver_10g,
      matchboxUrl        = var.matchbox_url
    }),
    file("talosPatches/registries.yaml"),
    (each.value.type == "controlplane") ? file("talosPatches/cpPatches.yaml") : null,
    (each.value.type == "worker") ? file("talosPatches/workerPatches.yaml") : null
  ]
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
}

resource "matchbox_profile" "machine" {
  for_each = var.nodes
  name     = "${each.value.type}-${each.value.hostname}"
  kernel   = local.kernel_cached_factory
  initrd   = [local.initrd_cached_factory]
  args = [
    "initrd=initramfs-amd64.xz",
    "init_on_alloc=1",
    "slab_nomerge",
    "pti=on",
    "printk.devkmsg=on",
    "talos.platform=metal",
    "talos.config=${var.matchbox_url}/ignition?mac=$${mac:hexhyp}",
    "net.ifnames=0"
  ]
  raw_ignition = data.talos_machine_configuration.machine[each.key].machine_configuration
}

resource "matchbox_group" "machine" {
  for_each = var.nodes
  name     = each.value.hostname
  profile  = matchbox_profile.machine[each.key].name
  selector = {
    mac = lower(each.value.mac_addr)
  }
}

data "talos_client_configuration" "talosconfig" {
  depends_on = [
    talos_machine_secrets.talos
  ]
  client_configuration = talos_machine_secrets.talos.client_configuration
  cluster_name         = var.cluster_name
  endpoints            = [for k, v in var.nodes : k if v.type == "controlplane"]
  nodes                = [for k, v in var.nodes : k]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count                = var.bootstrap ? 1 : 0
  client_configuration = talos_machine_secrets.talos.client_configuration
  node                 = element([for k, v in var.nodes : k if v.type == "controlplane"], 0)
  endpoint             = element([for k, v in var.nodes : k if v.type == "controlplane"], 0)
}
