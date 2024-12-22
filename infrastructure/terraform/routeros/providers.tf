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
      version = "1.72.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.1.1"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.13.0"
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
