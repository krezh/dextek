variable "domain" {
  type        = map(string)
  description = "Domain for Authentik"
  default = {
    external = "plexuz.xyz"
    internal = "talos.plexuz.xyz"
  }
}

variable "infisical_client_id" {
  sensitive = true
}

variable "infisical_client_secret" {
  sensitive = true
}
