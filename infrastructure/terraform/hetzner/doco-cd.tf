resource "docker_network" "pangolin" {
  depends_on = [ssh_resource.docker_tls_setup]

  name   = "pangolin"
  driver = "bridge"

  labels {
    label = "com.docker.compose.network"
    value = "default"
  }

  labels {
    label = "com.docker.compose.project"
    value = "pangolin"
  }
}

resource "docker_volume" "doco_cd_data" {
  depends_on = [ssh_resource.docker_tls_setup]

  name = "doco_cd_data"
}

resource "docker_image" "doco_cd" {
  depends_on = [ssh_resource.docker_tls_setup]

  name = "ghcr.io/kimdre/doco-cd:0.82.2@sha256:b3e3c28c7690e1f3cb7ad5cdbf2cecf34965a40ef3e89bf55bb21f221f1c0a20"
}

resource "docker_container" "doco_cd" {
  name    = "doco-cd"
  image   = docker_image.doco_cd.name
  restart = "unless-stopped"

  env = [
    "DEPLOY_CONFIG_BASE_DIR=./docker/vps-pangolin/",
    "LOG_LEVEL=info",
    "POLL_CONFIG=- url: https://github.com/krezh/dextek.git\n  reference: main\n  interval: 3600",
    "SECRET_PROVIDER=infisical",
    "SECRET_PROVIDER_SITE_URL=https://eu.infisical.com",
    "SECRET_PROVIDER_CLIENT_ID=${data.infisical_secrets.pangolin.secrets["INFISICAL_CLIENT_ID"].value}",
    "SECRET_PROVIDER_CLIENT_SECRET=${data.infisical_secrets.pangolin.secrets["INFISICAL_CLIENT_SECRET"].value}",
    "TZ=Europe/Stockholm",
  ]

  ports {
    internal = 8880
    external = 8880
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    volume_name    = docker_volume.doco_cd_data.name
    container_path = "/data"
  }

  networks_advanced {
    name = docker_network.pangolin.name
  }

  healthcheck {
    test         = ["CMD", "/doco-cd", "healthcheck"]
    start_period = "15s"
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
  }
}
