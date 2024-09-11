terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "talos"
    }
  }
  required_providers {
    sops = {
      source  = "lokkersp/sops"
      version = "0.6.10"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
  required_version = ">= 1.3.0"
}

provider "sops" {}
provider "local" {}
provider "talos" {}
provider "ssh" {}

provider "matchbox" {
  endpoint    = data.sops_file.secrets.data["matchbox.uri"]
  client_cert = data.sops_file.secrets.data["matchbox.client_crt"]
  client_key  = data.sops_file.secrets.data["matchbox.client_key"]
  ca          = data.sops_file.secrets.data["matchbox.ca_crt"]
}
