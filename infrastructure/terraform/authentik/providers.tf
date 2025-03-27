terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "authentik"
    }
  }
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.2.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.15.0"
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
  token = jsondecode(data.doppler_secrets.tf_authentik.map.AUTHENTIK)["AUTHENTIK_TOKEN"]
}
