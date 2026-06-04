resource "ssh_resource" "caddy_config" {
  depends_on = [ssh_resource.docker_tls_setup]

  triggers = {
    caddyfile = sha256(templatefile("${path.module}/config/Caddyfile", {
      CADDY_ACME_EMAIL = data.infisical_secrets.towonel.secrets["TOWONEL_ACME_EMAIL"].value
      VPS_LOCAL_HOSTS  = "twnl.plexuz.xyz"
    }))
  }

  host        = hcloud_server.towonel.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  pre_commands = [
    "mkdir -p /opt/caddy",
  ]

  file {
    content = templatefile("${path.module}/config/Caddyfile", {
      CADDY_ACME_EMAIL = data.infisical_secrets.towonel.secrets["TOWONEL_ACME_EMAIL"].value
      VPS_LOCAL_HOSTS  = "twnl.plexuz.xyz"
    })
    destination = "/opt/caddy/Caddyfile"
    permissions = "0644"
  }
}

resource "docker_image" "caddy_l4" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "ghcr.io/bjw-s-labs/caddy-l4:2.11.4"
}

resource "docker_volume" "caddy_data" {
  name = "caddy_data"
}

resource "docker_volume" "caddy_config" {
  name = "caddy_config"
}

resource "docker_container" "caddy" {
  depends_on = [
    ssh_resource.docker_tls_setup,
    ssh_resource.caddy_config,
    docker_network.edge,
    docker_container.towonel,
  ]

  name    = "caddy-l4"
  image   = docker_image.caddy_l4.name
  restart = "unless-stopped"

  ports {
    external = 80
    internal = 80
  }

  ports {
    external = 443
    internal = 443
  }

  volumes {
    volume_name    = docker_volume.caddy_data.id
    container_path = "/data"
  }

  volumes {
    volume_name    = docker_volume.caddy_config.id
    container_path = "/config"
  }

  volumes {
    host_path      = "/opt/caddy/Caddyfile"
    container_path = "/etc/caddy/Caddyfile"
    read_only      = true
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
