resource "routeros_interface_bridge" "bridge" {
  name              = "bridge"
  vlan_filtering    = true
  protocol_mode     = "rstp"
  ingress_filtering = true
  comment           = var.comment
}
