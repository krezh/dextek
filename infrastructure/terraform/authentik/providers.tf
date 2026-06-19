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
      version = "2026.5.0"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.32"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
}

provider "authentik" {
  url   = "https://sso.${var.domain}"
  token = ephemeral.infisical_secret.authentik_token.value
}
