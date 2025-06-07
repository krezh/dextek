terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
  }
  required_version = ">= 1.3.0"
}

provider "matchbox" {
  endpoint    = var.matchbox_api
  client_cert = var.matchbox_client_cert
  client_key  = var.matchbox_client_key
  ca          = var.matchbox_ca
}
