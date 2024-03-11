resource "routeros_ip_pool" "vlan200" {
  name   = "vlan200_pool"
  ranges = ["10.10.0.10-10.10.0.30"]
}

resource "routeros_ip_dhcp_server_option" "jumbo_frame_opt" {
  name  = "jumbo-mtu-opt"
  code  = 26
  value = "0x2328"
}

resource "routeros_ip_dhcp_server_option_set" "lan_option_set" {
  name    = "lan-option-set"
  options = join(",", [routeros_ip_dhcp_server_option.jumbo_frame_opt.name])
}

#resource "routeros_ip_dhcp_server_network" "dhcp_server_network" {
#  address         = "10.10.0.0/27"
#  netmask         = 27
#  domain          = "fast.dextek.io"
#  dns_none        = true
#  dhcp_option_set = routeros_ip_dhcp_server_option_set.lan_option_set.name
#}

resource "routeros_ip_dhcp_server" "dhcp200" {
  name                    = "dhcp200"
  address_pool            = routeros_ip_pool.vlan200.name
  interface               = routeros_interface_vlan.vlan200.name
  add_arp                 = true
  conflict_detection      = true
  use_framed_as_classless = true
  lease_time              = "30m"
}
