module "talos" {
  source                 = "./modules/talos"
  cluster_name           = "talos-plexuz"
  cluster_vip            = "192.168.20.5"
  cluster_endpoint       = "talos.k8s.plexuz.xyz"
  cluster_subnet         = "10.10.0.0/27"
  talos_version          = "v1.10.4" # renovate: datasource=docker depName=ghcr.io/siderolabs/installer
  kubernetes_version     = "v1.33.1" # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
  factory_schematic_file = "schematic.yaml"
  matchbox = {
    url         = "http://matchbox.int.plexuz.xyz:8080"
    api         = "matchbox.int.plexuz.xyz:8081"
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
    "ms01-01.k8s.plexuz.xyz" = {
      hostname   = "ms01-01"
      role       = "controlplane"
      mac_addr   = "58:47:ca:74:f2:40"
      disk_model = "Samsung SSD*"
      driver     = "igc"
      driver_10g = "i40e"
    }
    "ms01-02.k8s.plexuz.xyz" = {
      hostname   = "ms01-02"
      role       = "controlplane"
      mac_addr   = "58:47:ca:76:83:aa"
      disk_model = "Samsung SSD*"
      driver     = "igc"
      driver_10g = "i40e"
    }
    "ms01-03.k8s.plexuz.xyz" = {
      hostname   = "ms01-03"
      role       = "controlplane"
      mac_addr   = "58:47:ca:76:7f:52"
      disk_model = "Samsung SSD*"
      driver     = "igc"
      driver_10g = "i40e"
    }
  }
  bootstrap    = var.bootstrap
  talosconfig  = var.talosconfig
  machine_yaml = var.machine_yaml
}
