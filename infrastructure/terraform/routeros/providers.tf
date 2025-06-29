terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "routeros"
    }
  }
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.85.3"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.18.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "sops" {}

provider "routeros" {
  hosturl  = data.sops_file.secrets.data["routeros.ip"]
  username = data.doppler_secrets.prd_routeros.map.ADMIN_USER
  password = data.doppler_secrets.prd_routeros.map.ADMIN_PASSWORD
  insecure = true
}

provider "doppler" {
  doppler_token = data.sops_file.secrets.data["doppler.token"]
}
