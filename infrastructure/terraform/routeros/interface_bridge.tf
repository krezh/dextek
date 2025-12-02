resource "routeros_interface_bridge" "bridge" {
  name              = "bridge"
  vlan_filtering    = true
  protocol_mode     = "none"
  ingress_filtering = var.ingress_filtering
  comment           = "Default Bridge: ${var.comment}"
}
