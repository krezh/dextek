terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "hetzner"
    }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.16"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.2.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
}

provider "hcloud" {
  token = ephemeral.infisical_secret.hcloud_token.value
}

resource "local_sensitive_file" "ssh_key" {
  content         = local.ssh_key
  filename        = "/tmp/tofu_ssh_key"
  file_permission = "0600"
}

provider "docker" {
  host     = "ssh://${var.ssh_user}@${hcloud_server.pangolin.ipv4_address}"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", local_sensitive_file.ssh_key.filename]
}

