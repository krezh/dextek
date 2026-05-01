resource "ssh_resource" "fail2ban_config" {
  for_each = fileset("${path.module}/fail2ban", "**")

  triggers = {
    content = templatefile("${path.module}/fail2ban/${each.value}", {
      MY_IP = data.infisical_secrets.hetzner.secrets["MY_IP"].value
    })
  }

  host        = hcloud_server.pangolin.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  pre_commands = ["mkdir -p /opt/fail2ban/${dirname(each.value)}"]

  file {
    content = templatefile("${path.module}/fail2ban/${each.value}", {
      MY_IP = data.infisical_secrets.hetzner.secrets["MY_IP"].value
    })
    destination = "/opt/fail2ban/${each.value}"
    permissions = "0644"
  }
}

resource "ssh_resource" "fail2ban_config_cleanup" {
  for_each = fileset("${path.module}/fail2ban", "**")

  when        = "destroy"
  host        = hcloud_server.pangolin.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  commands = ["rm -f /opt/fail2ban/${each.value}"]
}

resource "docker_image" "fail2ban" {
  depends_on = [ssh_resource.docker_tls_setup]

  name = "crazymax/fail2ban:1.1.0"
}

resource "docker_container" "fail2ban" {
  depends_on = [
    ssh_resource.fail2ban_config,
    ssh_resource.docker_tls_setup
  ]

  name         = "fail2ban"
  image        = docker_image.fail2ban.name
  restart      = "unless-stopped"
  network_mode = "host"

  capabilities {
    add = ["CAP_NET_ADMIN", "CAP_NET_RAW"]
  }

  env = [
    "TZ=UTC",
    "F2B_LOG_LEVEL=INFO",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = "/var/log"
    container_path = "/var/log"
    read_only      = true
  }

  volumes {
    host_path      = "/opt/fail2ban"
    container_path = "/data"
  }
}
