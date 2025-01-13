terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "routeros"
    }
  }
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.12.0"
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
}

provider "sops" {}


data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

provider "doppler" {
  doppler_token = data.sops_file.secrets.data["doppler.token"]
}

data "doppler_secrets" "tf_authentik" {}

provider "authentik" {
  url   = "https://sso.${var.domain}"
  token = jsondecode(data.doppler_secrets.tf_authentik.map.AUTHENTIK)
}
