locals {
  cluster = yamldecode(file("cluster.yaml"))

  _nodes_raw = {
    for d in [for f in fileset("talosPatches/nodes", "*/00-node.yaml") : dirname(f)] : d => {
      role     = yamldecode(file("talosPatches/nodes/${d}/00-node.yaml")).machine.type
      platform = try(yamldecode(file("talosPatches/nodes/${d}/00-node.yaml")).talos.platform, "metal")
      mac_addrs = compact(flatten([
        for f in sort(fileset("talosPatches/nodes/${d}", "*.yaml")) : [
          for s in split("\n---", "\n${file("talosPatches/nodes/${d}/${f}")}") :
          try(
            regexall("(?i)[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}",
              yamldecode(trimspace(s)).selector.match)[0],
            null
          )
          if try(yamldecode(trimspace(s)).kind, "") == "LinkAliasConfig"
        ]
      ]))
    }
  }

  nodes = {
    for d, raw in local._nodes_raw : d => {
      hostname  = d
      role      = raw.role
      platform  = raw.platform
      mac_addrs = raw.mac_addrs
    }
  }

  patch_vars = {
    for k, v in local.nodes : k => merge({
      talos_version      = local.cluster.talos_version
      talos_factory_hash = talos_image_factory_schematic.machine.id
      factory_repo_url   = var.factory_repo_url
    }, var.template_vars)
  }
}

resource "talos_machine_secrets" "talos" {
  talos_version = local.cluster.talos_version
  lifecycle {
    ignore_changes = [talos_version]
  }
}

resource "talos_image_factory_schematic" "machine" {
  schematic = file(var.factory_schematic_file)
}

data "talos_machine_configuration" "machine" {
  for_each = local.nodes
  depends_on = [
    talos_machine_secrets.talos
  ]
  machine_type     = each.value.role
  cluster_name     = local.cluster.name
  cluster_endpoint = "https://${local.cluster.endpoint}:6443"

  talos_version      = local.cluster.talos_version
  kubernetes_version = local.cluster.kubernetes_version
  docs               = false
  examples           = false

  machine_secrets = talos_machine_secrets.talos.machine_secrets
  config_patches = concat(
    [for f in sort(fileset("talosPatches/all", "*.yaml")) :
      templatefile("talosPatches/all/${f}", local.patch_vars[each.key])],
    [for f in sort(fileset("talosPatches/${each.value.role}", "*.yaml")) :
      templatefile("talosPatches/${each.value.role}/${f}", local.patch_vars[each.key])],
    [for f in sort(try(fileset("talosPatches/nodes/${each.value.hostname}", "*.yaml"), [])) :
      templatefile("talosPatches/nodes/${each.value.hostname}/${f}", local.patch_vars[each.key])],
  )
}

resource "matchbox_profile" "machine" {
  for_each = local.nodes
  name     = "${each.value.role}-${each.value.hostname}"
  kernel   = local.factory_kernel_url
  initrd   = [local.factory_initrd_url]
  args = [
    "initrd=initramfs-amd64.xz",
    "init_on_alloc=1",
    "slab_nomerge",
    "pti=on",
    "printk.devkmsg=on",
    "panic=60",
    "talos.platform=${each.value.platform}",
    "talos.config=${var.matchbox.url}/ignition?mac=$${mac:hexhyp}"
  ]
  raw_ignition = data.talos_machine_configuration.machine[each.key].machine_configuration
}

locals {
  _node_macs = flatten([
    for hostname, node in local.nodes : [
      for mac in node.mac_addrs : {
        key      = "${hostname}-${mac}"
        hostname = hostname
        mac      = mac
      }
    ]
  ])
}

resource "matchbox_group" "machine_mac" {
  for_each = { for m in local._node_macs : m.key => m }
  name     = each.key
  profile  = matchbox_profile.machine[each.value.hostname].name
  selector = {
    mac = lower(each.value.mac)
  }
}

data "talos_client_configuration" "talosconfig" {
  depends_on = [
    talos_machine_secrets.talos
  ]
  client_configuration = talos_machine_secrets.talos.client_configuration
  cluster_name         = local.cluster.name
  endpoints            = [for k, v in local.nodes : k if v.role == "controlplane"]
  nodes                = [for k, v in local.nodes : k]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count                = var.bootstrap ? 1 : 0
  client_configuration = talos_machine_secrets.talos.client_configuration
  node                 = element([for k, v in local.nodes : k if v.role == "controlplane"], 0)
  endpoint             = element([for k, v in local.nodes : k if v.role == "controlplane"], 0)
}
