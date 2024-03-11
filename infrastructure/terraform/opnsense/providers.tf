terraform {
  cloud {
    organization = "krezh"
    hostname     = "app.terraform.io"
    workspaces {
      name = "opnsense"
    }
  }
  required_providers {
    opnsense = {
      source  = "browningluke/opnsense"
      version = "0.10.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}

provider "opnsense" {
  uri        = data.sops_file.secrets.data["opnsense_uri"]
  api_key    = data.sops_file.secrets.data["opnsense_api_key"]
  api_secret = data.sops_file.secrets.data["opnsense_api_secret"]
}
