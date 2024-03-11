resource "opnsense_firewall_alias" "ingress_public" {
  name        = "Ingress_Public"
  type        = "host"
  content     = ["ingress-public.talos.plexuz.xyz"]
  categories  = [opnsense_firewall_category.kubernetes.id]
  description = "Kubernetes Loadbalancer for Public Ingress"
  stats       = true
}

resource "opnsense_firewall_alias" "plex_lb" {
  name        = "Plex_LB"
  type        = "host"
  content     = ["plex-lb.talos.plexuz.xyz"]
  categories  = [opnsense_firewall_category.kubernetes.id]
  description = "Kubernetes Loadbalancer for Plex Media Server"
  stats       = true
}

resource "opnsense_firewall_alias" "cloudflare_ips" {
  name        = "Cloudflare_IPs"
  type        = "urltable"
  content     = ["https://www.cloudflare.com/ips-v4", "https://www.cloudflare.com/ips-v6"]
  categories  = [opnsense_firewall_category.kubernetes.id]
  description = "Cloudflare IPs"
  stats       = true
  update_freq = 1
}
