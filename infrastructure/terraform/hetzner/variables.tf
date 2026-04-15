variable "ssh_user" {
  default = "root"
}

locals {
  ssh_key = fileexists("~/.ssh/id_ed25519") ? file("~/.ssh/id_ed25519") : ephemeral.infisical_secret.ssh_private_key.value
}
