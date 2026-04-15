resource "hcloud_network" "default" {
  name     = "Default"
  ip_range = "10.0.0.0/24"
}

resource "hcloud_network_subnet" "default" {
  network_id   = hcloud_network.default.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}
