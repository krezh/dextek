terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "talos"
    }
  }
  required_providers {
    infisical = {
      source  = "Infisical/infisical"
      version = "0.16.22"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
  }
  required_version = ">= 1.3.0"
}

provider "infisical" {
  host = "https://eu.infisical.com"
}
