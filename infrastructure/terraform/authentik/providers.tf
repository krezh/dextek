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
      version = "2025.12.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.14"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

provider "infisical" {
  host = "https://eu.infisical.com"
  auth = {
    universal = {
      client_id     = data.sops_file.secrets.data["infisical.client_id"]
      client_secret = data.sops_file.secrets.data["infisical.client_secret"]
    }
  }
}

provider "authentik" {
  url   = "https://sso.${var.domain["external"]}"
  token = ephemeral.infisical_secret.authentik_token.value
}
