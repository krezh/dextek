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
      version = "1.62.0"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.20"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.2.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
}

provider "hcloud" {
  token = ephemeral.infisical_secret.hcloud_token.value
}

provider "docker" {
  host          = "tcp://${hcloud_server.pangolin.ipv4_address}:2376"
  ca_material   = tls_self_signed_cert.docker_ca.cert_pem
  cert_material = tls_locally_signed_cert.docker_client.cert_pem
  key_material  = tls_private_key.docker_client.private_key_pem
}

