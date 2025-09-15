variable "domain" {
  type        = map(string)
  description = "Domain for Authentik"
  default = {
    external = "plexuz.xyz"
    internal = "talos.plexuz.xyz"
  }
}
