resource "hcloud_firewall" "inbound_https" {
  name = "Inbound HTTP/S"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

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

resource "hcloud_firewall" "pangolin" {
  name = "Pangolin"

  rule {
    description = "Docker TLS"
    direction   = "in"
    protocol    = "tcp"
    port        = "2376"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "SSH Tunneling"
    direction   = "in"
    protocol    = "tcp"
    port        = "2222"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "WireGuard"
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Gerbil"
    direction   = "in"
    protocol    = "udp"
    port        = "21820"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
