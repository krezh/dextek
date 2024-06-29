# Accept Flux Github Webhook
resource "cloudflare_filter" "domain_github_flux_webhook" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Allow GitHub flux API"
  expression  = "(http.host eq \"fluxhook.${each.value}\" and ip.geoip.asnum eq 36459)"
}
resource "cloudflare_firewall_rule" "domain_github_flux_webhook" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Allow GitHub flux API"
  filter_id   = cloudflare_filter.domain_github_flux_webhook[each.key].id
  action      = "allow"
  priority    = 1
}

# Accept Paths
resource "cloudflare_filter" "allowed_paths" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Allow Specified paths"
  expression  = "(http.request.uri.path contains \"/feed/\") or (http.request.uri.path contains \"/api/\") or (http.user_agent eq \"Google-Calendar-Importer\") or (http.request.uri.path contains \"/image/\") or (http.request.uri.path contains \"/api2/json/\") or (http.user_agent contains \"Shields.io\")"
}
resource "cloudflare_firewall_rule" "allowed_paths" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Allow Specified paths"
  filter_id   = cloudflare_filter.allowed_paths[each.key].id
  action      = "allow"
  priority    = 2
}

# Block Countries
resource "cloudflare_filter" "block_countries" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Expression to block countries"
  expression  = "(not ip.geoip.country in {\"SE\"})"
}
resource "cloudflare_firewall_rule" "block_countries" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Firewall rule to block countries"
  filter_id   = cloudflare_filter.block_countries[each.key].id
  action      = "block"
  priority    = 10
}

# Block Bots
resource "cloudflare_filter" "bots" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Expression to block bots determined by CF"
  expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
}

resource "cloudflare_firewall_rule" "bots" {
  for_each    = toset(var.domains)
  zone_id     = data.cloudflare_zone.domain[each.key].id
  description = "Firewall rule to block bots determined by CF"
  filter_id   = cloudflare_filter.bots[each.key].id
  action      = "block"
  priority    = 20
}
