variable "ssh_user" {
  default = "root"
}

locals {
  ssh_key = data.infisical_secrets.hetzner.secrets["SSH_PRIVATE_KEY"].value
}
