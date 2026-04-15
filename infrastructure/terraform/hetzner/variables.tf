variable "ssh_user" {
  default = "root"
}

locals {
  ssh_key = file("~/.ssh/id_ed25519")
}
