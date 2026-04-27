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
    description = "SSH Tunneling"
    direction   = "in"
    protocol    = "tcp"
    port        = "2222"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Towonel Hub"
    direction   = "in"
    protocol    = "tcp"
    port        = "8443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
