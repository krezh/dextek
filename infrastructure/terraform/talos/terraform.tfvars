nodes = {
  "asgard.k8s.plexuz.xyz" = {
    hostname      = "asgard"
    type          = "controlplane"
    mac_addr      = "ec:f4:bb:ce:5e:3c"
    disk_model    = ""
    driver        = "igb"
    driver_10g    = "ixgbe"
  },
  "vanaheim.k8s.plexuz.xyz" = {
    hostname      = "vanaheim"
    type          = "controlplane"
    mac_addr      = "18:66:da:89:08:49"
    disk_model    = ""
    driver        = "tg3"
    driver_10g    = "ixgbe"
  },
  "alfheim.k8s.plexuz.xyz" = {
    hostname      = "alfheim"
    type          = "controlplane"
    mac_addr      = "e4:43:4b:6e:55:cc"
    disk_model    = ""
    driver        = "igb"
    driver_10g    = "ixgbe"
  },
  "ms01-01.k8s.plexuz.xyz" = {
    hostname      = "ms01-01"
    type          = "worker"
    mac_addr      = "58:47:ca:74:f2:40"
    disk_model    = "Samsung SSD*"
    driver        = "igc"
    driver_10g    = "i40e"
  },
  "ms01-02.k8s.plexuz.xyz" = {
    hostname      = "ms01-02"
    type          = "worker"
    mac_addr      = "58:47:ca:76:83:aa"
    disk_model    = "Samsung SSD*"
    driver        = "igc"
    driver_10g    = "i40e"
  }
}

vip = "192.168.20.5"