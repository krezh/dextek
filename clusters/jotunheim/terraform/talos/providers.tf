terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "talos-jotunheim"
    }
  }
  required_providers {
    sops = {
      source  = "lokkersp/sops"
      version = "0.6.10"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
  }
  required_version = ">= 1.3.0"
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}
