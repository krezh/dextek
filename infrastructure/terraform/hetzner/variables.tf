variable "ssh_user" {
  default = "root"
}

locals {
  ssh_key = fileexists("~/.ssh/id_ed25519") ? file("~/.ssh/id_ed25519") : data.infisical_secrets.hetzner.secrets["SSH_PRIVATE_KEY"].value
}
