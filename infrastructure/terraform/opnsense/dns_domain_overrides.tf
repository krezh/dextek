resource "opnsense_unbound_domain_override" "talos" {
  enabled     = true
  domain      = "talos.plexuz.xyz"
  server      = "192.168.20.50"
  description = "Talos K8S Gateway"
}

resource "opnsense_unbound_domain_override" "jotunheim" {
  enabled     = true
  domain      = "int.plexuz.xyz"
  server      = "192.168.20.2"
  description = "Jotunheim K8S Gateway"
}
