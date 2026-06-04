resource "docker_network" "edge" {
  depends_on = [ssh_resource.docker_tls_setup]

  name   = "edge"
  driver = "bridge"
}

resource "docker_image" "towonel" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "codeberg.org/towonel/towonel-node:0.1.20"
}

resource "docker_volume" "towonel_data" {
  name = "towonel_data"
}

resource "docker_container" "towonel" {
  depends_on = [
    ssh_resource.docker_tls_setup,
    docker_network.edge
  ]

  name        = "towonel-node"
  image       = docker_image.towonel.name
  restart     = "unless-stopped"
  user        = "10001:10001"
  memory_swap = 1024
  env = [
    "RUST_LOG=info",
    "TOWONEL_INVITE_HASH_KEY=${data.infisical_secrets.towonel.secrets["TOWONEL_INVITE_HASH_KEY"].value}",
    "TOWONEL_HUB_ENABLED=true",
    "TOWONEL_HUB_OPERATOR_API_KEY=${data.infisical_secrets.towonel.secrets["TOWONEL_HUB_OPERATOR_API_KEY"].value}",
    "TOWONEL_HUB_KEK=${data.infisical_secrets.towonel.secrets["TOWONEL_HUB_KEK"].value}",
    "TOWONEL_HUB_ALLOW_PRIVILEGED_PORTS=true",
    "TOWONEL_HUB_PUBLIC_URL=https://twnl.plexuz.xyz",
    "TOWONEL_EDGE_ENABLED=true",
    "TOWONEL_EDGE_HEALTH_LISTEN_ADDR=0.0.0.0:9092",
    "TOWONEL_EDGE_IROH_PORT=51820",
    "TOWONEL_EDGE_LISTEN_ADDR=0.0.0.0:4443",
    "TOWONEL_EDGE_PROXY_PROTOCOL=true",
  ]

  volumes {
    volume_name    = docker_volume.towonel_data.id
    container_path = "/data"
    read_only      = false
  }

  ports {
    external = 51820
    internal = 51820
    protocol = "udp"
  }

  networks_advanced {
    name = docker_network.edge.name
  }

  healthcheck {
    test         = ["CMD", "curl", "-fsS", "-o", "/dev/null", "http://127.0.0.1:8443/v1/health"]
    start_period = "30s"
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
  }

  memory = 512

  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}
