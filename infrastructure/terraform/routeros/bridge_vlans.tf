resource "routeros_interface_bridge_vlan" "vlan10" {
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [10]
  tagged = [
    "bridge", "ether1",
    routeros_interface_bridge_port.asgard_eth0.interface,
    routeros_interface_bridge_port.vanaheim_eth0.interface,
    routeros_interface_bridge_port.alfheim_eth0.interface,
    routeros_interface_bridge_port.ms01-01_eth0.interface,
    routeros_interface_bridge_port.ms01-02_eth0.interface,
    routeros_interface_bridge_port.ms01-03_eth0.interface,
  ]
  untagged = []
  comment  = "SRV: ${var.comment}"
}

resource "routeros_interface_bridge_vlan" "vlan20" {
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [20]
  tagged   = ["bridge", "ether1", "ether9"]
  untagged = []
  comment  = "K8S: ${var.comment}"
}

resource "routeros_interface_bridge_vlan" "vlan50" {
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [50]
  tagged   = ["bridge", "ether1", "ether23", "ether24"]
  untagged = []
  comment  = "WIFI: ${var.comment}"
}

resource "routeros_interface_bridge_vlan" "vlan100" {
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [100]
  tagged = [
    "bridge", "ether1",
    routeros_interface_bridge_port.asgard_eth0.interface,
    routeros_interface_bridge_port.vanaheim_eth0.interface,
    routeros_interface_bridge_port.alfheim_eth0.interface,
    routeros_interface_bridge_port.ms01-01_eth0.interface,
    routeros_interface_bridge_port.ms01-02_eth0.interface,
    routeros_interface_bridge_port.ms01-03_eth0.interface,
    "ether23", "ether24"
  ]
  untagged = []
  comment  = "IoT: ${var.comment}"
}

resource "routeros_interface_bridge_vlan" "vlan200" {
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [200]
  tagged   = ["bridge"]
  untagged = []
  comment  = "FAST: ${var.comment}"
}
