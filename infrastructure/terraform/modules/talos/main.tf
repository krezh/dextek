resource "talos_machine_secrets" "talos" {
  talos_version = var.talos_version
  lifecycle {
    prevent_destroy = true
  }
}

resource "talos_image_factory_schematic" "machine" {
  schematic = file(var.factory_schematic_file)
}

data "talos_machine_configuration" "machine" {
  for_each = var.nodes
  depends_on = [
    talos_machine_secrets.talos
  ]
  machine_type     = each.value.role
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false

  machine_secrets = talos_machine_secrets.talos.machine_secrets
  config_patches = [
    templatefile("talosPatches/general.yaml", {
      cluster_name       = var.cluster_name,
      talos_version      = var.talos_version,
      talos_factory_hash = talos_image_factory_schematic.machine.id,
      factory_repo_url   = var.factory_repo_url,
      cluster_subnet     = var.cluster_subnet,
      cluster_endpoint   = var.cluster_endpoint,
      upsmonHost         = var.upsmon.host,
      upsmonPasswd       = var.upsmon.password,
      hostname           = each.key,
      disk_model         = each.value.disk_model,
      mac_addr           = each.value.mac_addr,
      cluster_vip        = var.cluster_vip,
      driver             = each.value.driver,
      driver_10g         = each.value.driver_10g,
      matchboxUrl        = var.matchbox.url,
    }),
    file("talosPatches/registries.yaml"),
    each.value.role == "controlplane" ? file("talosPatches/controlplane.yaml") : null,
    each.value.role == "worker" ? file("talosPatches/worker.yaml") : null,
    # This patch is for the NUT UPS monitoring
    templatefile("talosPatches/nut.yaml", {
      upsmonHost   = var.upsmon.host,
      upsmonPasswd = var.upsmon.password
    })
  ]
}

resource "matchbox_profile" "machine" {
  for_each = var.nodes
  name     = "${each.value.role}-${each.value.hostname}"
  kernel   = local.factory_kernel_url
  initrd   = [local.factory_initrd_url]
  args = [
    "initrd=initramfs-amd64.xz",
    "init_on_alloc=1",
    "slab_nomerge",
    "pti=on",
    "printk.devkmsg=on",
    "talos.platform=${each.value.platform}",
    "talos.config=${var.matchbox.url}/ignition?mac=$${mac:hexhyp}"
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
  endpoints            = [for k, v in var.nodes : k if v.role == "controlplane"]
  nodes                = [for k, v in var.nodes : k]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count                = var.bootstrap ? 1 : 0
  client_configuration = talos_machine_secrets.talos.client_configuration
  node                 = element([for k, v in var.nodes : k if v.role == "controlplane"], 0)
  endpoint             = element([for k, v in var.nodes : k if v.role == "controlplane"], 0)
}
