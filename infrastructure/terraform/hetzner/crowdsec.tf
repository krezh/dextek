resource "random_bytes" "crowdsec_bouncer_key" {
  length = 32
}

resource "ssh_resource" "crowdsec_bouncer_config" {
  triggers = {
    bouncer_key = random_bytes.crowdsec_bouncer_key.hex
  }

  host        = hcloud_server.towonel.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  pre_commands = ["mkdir -p /opt/crowdsec-bouncer"]

  file {
    content     = <<-EOT
      mode: nftables
      update_frequency: 10s

      log_mode: stdout
      log_level: info
      disable_ipv6: false
      deny_action: DROP
      deny_log: true
      supported_decisions_types:
        - ban
      nftables:
        enabled: true
        ipv4_table: crowdsec
        ipv6_table: crowdsec6
        ipv4_chain: crowdsec-chain
        ipv6_chain: crowdsec-chain
    EOT
    destination = "/opt/crowdsec-bouncer/crowdsec-firewall-bouncer.yaml"
    permissions = "0600"
  }
}

resource "docker_volume" "crowdsec_db" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "crowdsec_db"
}

resource "docker_volume" "crowdsec_config" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "crowdsec_config"
}

resource "ssh_resource" "crowdsec_config" {
  for_each = fileset("${path.module}/crowdsec", "**")

  triggers = {
    content = file("${path.module}/crowdsec/${each.value}")
  }

  host        = hcloud_server.towonel.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  pre_commands = ["mkdir -p /opt/crowdsec/${dirname(each.value)}"]

  file {
    content     = file("${path.module}/crowdsec/${each.value}")
    destination = "/opt/crowdsec/${each.value}"
    permissions = "0644"
  }
}

resource "ssh_resource" "crowdsec_config_cleanup" {
  for_each = fileset("${path.module}/crowdsec", "**")

  when        = "destroy"
  host        = hcloud_server.towonel.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  commands = ["rm -f /opt/crowdsec/${each.value}"]
}

resource "docker_container" "crowdsec" {
  depends_on = [
    ssh_resource.crowdsec_config,
    ssh_resource.docker_tls_setup,
    docker_network.edge,
  ]

  name        = "crowdsec"
  image       = "crowdsecurity/crowdsec:v1.7.8"
  restart     = "unless-stopped"
  memory      = 512
  memory_swap = 1024

  env = [
    "COLLECTIONS=crowdsecurity/linux crowdsecurity/sshd crowdsecurity/iptables",
    "PARSERS=crowdsecurity/geoip-enrich",
    "GID=1000",
    "BOUNCER_KEY_firewall=${random_bytes.crowdsec_bouncer_key.hex}",
  ]

  volumes {
    host_path      = "/var/log"
    container_path = "/var/log"
    read_only      = true
  }

  volumes {
    host_path      = "/run/systemd/journal"
    container_path = "/run/systemd/journal"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.crowdsec_db.name
    container_path = "/var/lib/crowdsec/data"
  }

  volumes {
    volume_name    = docker_volume.crowdsec_config.name
    container_path = "/etc/crowdsec"
  }

  volumes {
    host_path      = "/opt/crowdsec/acquis.d"
    container_path = "/etc/crowdsec/acquis.d"
    read_only      = true
  }

  volumes {
    host_path      = "/opt/crowdsec/whitelists"
    container_path = "/etc/crowdsec/parsers/s02-enrich/custom"
    read_only      = true
  }

  volumes {
    host_path      = "/opt/crowdsec/scenarios"
    container_path = "/etc/crowdsec/scenarios/custom"
    read_only      = true
  }

  volumes {
    host_path      = "/opt/crowdsec/config/config.yaml.local"
    container_path = "/etc/crowdsec/config.yaml.local"
    read_only      = true
  }

  ports {
    internal = 8080
    external = 8088
    ip       = "127.0.0.1"
  }

  healthcheck {
    test         = ["CMD", "cscli", "lapi", "status"]
    interval     = "30s"
    timeout      = "5s"
    start_period = "1m0s"
    retries      = 3
  }

  networks_advanced {
    name = docker_network.edge.name
  }

  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

resource "docker_image" "cs_firewall_bouncer" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "davidbcn86/crowdsec-firewall-bouncer-docker:v1.0.0-debian-12-bouncer-0.0.34-nftables"
}

resource "docker_container" "cs_firewall_bouncer" {
  depends_on = [
    docker_container.crowdsec,
    ssh_resource.crowdsec_bouncer_config,
    ssh_resource.docker_tls_setup,
  ]

  name         = "crowdsec-firewall-bouncer"
  image        = docker_image.cs_firewall_bouncer.name
  restart      = "unless-stopped"
  network_mode = "host"
  privileged   = true

  capabilities {
    add = ["CAP_NET_ADMIN", "CAP_NET_RAW", "CAP_SYS_ADMIN"]
  }

  env = [
    "CROWDSEC_API_URL=http://127.0.0.1:8088",
    "CROWDSEC_API_KEY=${random_bytes.crowdsec_bouncer_key.hex}",
  ]

  volumes {
    host_path      = "/opt/crowdsec-bouncer"
    container_path = "/tmp/crowdsec-config-source"
    read_only      = true
  }

  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}
