terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "matchbox" {
  endpoint    = var.matchbox.api
  client_cert = var.matchbox.client_cert
  client_key  = var.matchbox.client_key
  ca          = var.matchbox.ca
}
