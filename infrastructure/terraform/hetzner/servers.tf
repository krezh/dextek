data "hcloud_ssh_keys" "all" {}

resource "hcloud_server" "towonel" {
  depends_on = [hcloud_network_subnet.default]

  name        = "Towonel"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "hel1"

  ssh_keys = data.hcloud_ssh_keys.all.ssh_keys[*].name

  firewall_ids = [
    hcloud_firewall.inbound_https.id,
    hcloud_firewall.default.id,
    hcloud_firewall.towonel.id,
  ]

  network {
    network_id = hcloud_network.default.id
  }

  lifecycle {
    ignore_changes = [ssh_keys, user_data, image, network]
  }
}
