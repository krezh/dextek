terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces { name = "routeros" }
  }
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.99.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.21.2"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.46.2"
    }
  }
  required_version = ">= 1.3.0"
}

provider "sops" {}

provider "routeros" {
  hosturl  = "https://192.168.1.35"
  username = data.doppler_secrets.prd_routeros.map.ADMIN_USER
  password = data.doppler_secrets.prd_routeros.map.ADMIN_PASSWORD
  insecure = true
}

provider "doppler" {
  doppler_token = data.sops_file.secrets.data["doppler.token"]
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
