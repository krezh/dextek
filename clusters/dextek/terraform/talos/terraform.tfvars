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

cluster_name       = "talos-plexuz"
vip                = "192.168.20.5"
cluster_endpoint   = "https://192.168.20.5:6443"
talos_version      = "v1.10.2" # renovate: datasource=docker depName=ghcr.io/siderolabs/installer
kubernetes_version = "v1.33.1" # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
matchbox_url       = "http://matchbox.int.plexuz.xyz:8080"
factory_repo_url   = "factory.talos.dev"
