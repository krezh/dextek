variable "infisical_client_id" {
  sensitive = true
}

variable "infisical_client_secret" {
  sensitive = true
}

variable "ssh_user" {
  default = "root"
}

locals {
  ssh_key = file("~/.ssh/id_ed25519")
}
