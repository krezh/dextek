resource "cloudflare_record" "ipv4" {
  for_each = toset(var.domains)
  name     = "ingress"
  zone_id  = data.cloudflare_zone.domain[each.key].id
  value    = chomp(data.http.ipv4.response_body)
  proxied  = true
  type     = "A"
  ttl      = 1
}
