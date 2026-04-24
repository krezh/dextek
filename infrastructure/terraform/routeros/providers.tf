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
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.18"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.48.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "routeros" {
  hosturl  = "https://192.168.1.35"
  username = data.infisical_secrets.routeros.secrets["ADMIN_USER"].value
  password = data.infisical_secrets.routeros.secrets["ADMIN_PASSWORD"].value
  insecure = true
}

provider "infisical" {
  host = "https://eu.infisical.com"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
