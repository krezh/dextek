module "talos" {
  source                 = "../../../../infrastructure/terraform/modules/talos"
  cluster_name           = "talos-jotunheim"
  cluster_vip            = "192.168.20.6"
  cluster_endpoint       = "talos2.k8s.plexuz.xyz"
  cluster_subnet         = "192.168.20.0/24"
  talos_version          = "v1.10.3" # renovate: datasource=github-releases depName=siderolabs/talos
  kubernetes_version     = "v1.33.1" # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
  factory_schematic_file = "schematic.yaml"
  matchbox = {
    url         = "http://matchbox.int.plexuz.xyz:8080"
    api         = "matchbox.int.plexuz.xyz:8081"
    host        = "matchbox.int.plexuz.xyz"
    user        = "matchbox"
    private_key = data.sops_file.secrets.data["matchbox.sshkey"]
    client_cert = data.sops_file.secrets.data["matchbox.client_crt"]
    client_key  = data.sops_file.secrets.data["matchbox.client_key"]
    ca          = data.sops_file.secrets.data["matchbox.ca_crt"]
  }
  upsmon = {
    host     = data.sops_file.secrets.data["nut.host"]
    password = data.sops_file.secrets.data["nut.password"]
  }
  nodes = {
    "test3.k8s.plexuz.xyz" = {
      hostname   = "test3"
      platform   = "metal"
      role       = "controlplane"
      mac_addr   = "00:16:3e:b1:59:f5"
      disk_model = "QEMU*"
      driver     = "virtio_net"
    }
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
