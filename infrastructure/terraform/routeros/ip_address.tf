resource "routeros_ip_address" "vlan200" {
  address   = "10.10.0.1/27"
  interface = routeros_interface_vlan.vlan200.name
  network   = "10.10.0.0"
}
