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
      version = "0.19.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "routeros" {
  hosturl  = "http://192.168.1.35"
  username = data.infisical_secrets.routeros.secrets["ADMIN_USER"].value
  password = data.infisical_secrets.routeros.secrets["ADMIN_PASSWORD"].value
  insecure = true
}

provider "infisical" {
  host = "https://eu.infisical.com"
}
