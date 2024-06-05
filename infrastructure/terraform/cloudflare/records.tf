resource "cloudflare_record" "ipv4" {
  for_each = toset(var.domains)
  name     = "ingress"
  zone_id  = data.cloudflare_zone.domain[each.key].id
  value    = chomp(data.http.ipv4.response_body)
  proxied  = true
  type     = "A"
  ttl      = 1
}

resource "cloudflare_record" "doppler" {
  for_each = toset(var.domains)
  name     = "_doppler_O9Zugt4K0nNkt"
  zone_id  = data.cloudflare_zone.domain[each.key].id
  value    = "5d0SML7ayFMKTmY18mJ6FQI3L1HB4EFq"
  type     = "TXT"
}
