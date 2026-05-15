resource "docker_network" "edge" {
  depends_on = [ssh_resource.docker_tls_setup]

  name   = "edge"
  driver = "bridge"
}

resource "docker_image" "towonel" {
  depends_on = [ssh_resource.docker_tls_setup]
  name       = "registry.erwanleboucher.dev/eleboucher/towonel-node:0.0.28"
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
    "TOWONEL_IDENTITY_KEY_PATH=/data/node.key",
    "TOWONEL_INVITE_HASH_KEY=${data.infisical_secrets.towonel.secrets["TOWONEL_INVITE_HASH_KEY"].value}",
    "TOWONEL_HUB_ENABLED=true",
    "TOWONEL_HUB_ALLOW_PRIVILEGED_PORTS=true",
    "TOWONEL_HUB_DB_DRIVER=sqlite",
    "TOWONEL_HUB_DB_DSN=/data/hub.db",
    "TOWONEL_HUB_LISTEN_ADDR=0.0.0.0:8443",
    "TOWONEL_HUB_HEALTH_LISTEN_ADDR=0.0.0.0:9091",
    "TOWONEL_HUB_PUBLIC_URL=https://twnl.plexuz.xyz",
    "TOWONEL_HUB_OPERATOR_API_KEY_PATH=/data/operator.key",
    "TOWONEL_HUB_URL=http://localhost:8443",
    "TOWONEL_EDGE_ENABLED=true",
    "TOWONEL_EDGE_LISTEN_ADDR=0.0.0.0:443",
    "TOWONEL_EDGE_HEALTH_LISTEN_ADDR=0.0.0.0:9092",
    "TOWONEL_EDGE_PUBLIC_ADDRESSES=tunnel.plexuz.xyz:443",
    "TOWONEL_EDGE_TLS_CERT_DIR=/data/certs",
    "TOWONEL_EDGE_TLS_ACME_EMAIL=${data.infisical_secrets.towonel.secrets["TOWONEL_ACME_EMAIL"].value}",
    "TOWONEL_EDGE_TLS_HTTP_LISTEN_ADDR=0.0.0.0:80",
  ]

  volumes {
    volume_name    = "towonel_data"
    container_path = "/data"
  }

  ports {
    external = 443
    internal = 443
  }

  ports {
    external = 8443
    internal = 8443
  }

  ports {
    external = 80
    internal = 80
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
