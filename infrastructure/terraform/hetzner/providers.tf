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
      version = "0.16.15"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.2.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

provider "hcloud" {
  token = ephemeral.infisical_secret.hcloud_token.value
}

provider "docker" {
  host = "ssh://${var.ssh_user}@${hcloud_server.pangolin.ipv4_address}"
}

