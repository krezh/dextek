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
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.16"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
}

provider "authentik" {
  url   = "https://sso.${var.domain["external"]}"
  token = ephemeral.infisical_secret.authentik_token.value
}
