nodes = {
  "ms01-01.k8s.plexuz.xyz" = {
    hostname   = "ms01-01"
    type       = "controlplane"
    mac_addr   = "58:47:ca:74:f2:40"
    disk_model = "Samsung SSD*"
    driver     = "igc"
    driver_10g = "i40e"
  },
  "ms01-02.k8s.plexuz.xyz" = {
    hostname   = "ms01-02"
    type       = "controlplane"
    mac_addr   = "58:47:ca:76:83:aa"
    disk_model = "Samsung SSD*"
    driver     = "igc"
    driver_10g = "i40e"
  },
  "ms01-03.k8s.plexuz.xyz" = {
    hostname   = "ms01-03"
    type       = "controlplane"
    mac_addr   = "58:47:ca:76:7f:52"
    disk_model = "Samsung SSD*"
    driver     = "igc"
    driver_10g = "i40e"
  }
}

cluster_name = "talos-plexuz"
vip          = "192.168.20.5"
