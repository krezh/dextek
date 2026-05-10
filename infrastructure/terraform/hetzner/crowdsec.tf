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

resource "docker_image" "crowdsec" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "crowdsecurity/crowdsec:v1.7.7"
}

resource "docker_container" "crowdsec" {
  depends_on = [
    ssh_resource.crowdsec_config,
    ssh_resource.docker_tls_setup,
    docker_network.edge,
  ]

  name    = "crowdsec"
  image   = docker_image.crowdsec.name
  restart = "unless-stopped"
  memory  = 512

  env = [
    "COLLECTIONS=crowdsecurity/linux crowdsecurity/sshd crowdsecurity/iptables",
    "PARSERS=crowdsecurity/geoip-enrich",
    "GID=1000",
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
    container_path = "/etc/crowdsec/acquis.d/custom"
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
    start_period = "60s"
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
