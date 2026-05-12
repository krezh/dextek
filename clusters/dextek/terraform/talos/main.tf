module "talos" {
  source = "github.com/krezh/dextek//infrastructure/terraform/modules/talos?ref=main"
  # source                 = "../../../../infrastructure/terraform/modules/talos"
  cluster_name           = "dextek"
  cluster_vip            = "192.168.25.20"
  cluster_endpoint       = "192.168.25.20"
  cluster_subnet         = "10.10.0.0/27"
  talos_version          = "v1.13.1" # renovate: datasource=custom.talos-factory depName=siderolabs/talos
  kubernetes_version     = "v1.36.0" # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
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
  upsmon = {
    host     = data.infisical_secrets.nut.secrets["HOST"].value
    password = data.infisical_secrets.nut.secrets["PASSWORD"].value
  }
  nodes = {
    "ms01-01.k8s.plexuz.xyz" = {
      hostname      = "ms01-01"
      platform      = "metal"
      role          = "controlplane"
      mac_addr      = "58:47:ca:74:f2:40"
      mac_addr2     = "58:47:ca:74:f2:3f"
      mac_addr_10g  = "58:47:ca:74:f2:3d"
      disk_model    = "Samsung SSD*"
      driver        = "igc"
      driver_10g    = "i40e"
      static_ip_10g = "10.10.0.23"
      node_labels = {
        "node.kubernetes.io/gpu"        = "true"
        "topology.kubernetes.io/region" = "main"
      }
    }
    "ms01-02.k8s.plexuz.xyz" = {
      hostname      = "ms01-02"
      platform      = "metal"
      role          = "controlplane"
      mac_addr      = "58:47:ca:76:83:aa"
      mac_addr2     = "58:47:ca:76:83:a9"
      mac_addr_10g  = "58:47:ca:76:83:a7"
      disk_model    = "Samsung SSD*"
      driver        = "igc"
      driver_10g    = "i40e"
      static_ip_10g = "10.10.0.22"
      node_labels = {
        "node.kubernetes.io/gpu"        = "true"
        "topology.kubernetes.io/region" = "main"
      }
    }
    "ms01-03.k8s.plexuz.xyz" = {
      hostname      = "ms01-03"
      platform      = "metal"
      role          = "controlplane"
      mac_addr      = "58:47:ca:76:7f:52"
      mac_addr2     = "58:47:ca:76:7f:51"
      mac_addr_10g  = "58:47:ca:76:7f:4f"
      disk_model    = "Samsung SSD*"
      driver        = "igc"
      driver_10g    = "i40e"
      static_ip_10g = "10.10.0.21"
      node_labels = {
        "node.kubernetes.io/gpu"        = "true"
        "topology.kubernetes.io/region" = "main"
      }
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
