resource "hcloud_firewall" "inbound_https" {
  name = "Inbound HTTP/S"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "default" {
  name = "Default"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "towonel" {
  name = "Towonel"

  rule {
    description = "Docker TLS"
    direction   = "in"
    protocol    = "tcp"
    port        = "2376"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Edge TCP"
    direction   = "in"
    protocol    = "tcp"
    port        = "4443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Iroh QUIC"
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
