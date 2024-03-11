resource "routeros_interface_vlan" "vlan200" {
  interface = routeros_interface_bridge.bridge.name
  name      = "vlan200"
  vlan_id   = 200
  mtu       = 9000
}
