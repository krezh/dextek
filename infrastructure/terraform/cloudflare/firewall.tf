resource "cloudflare_ruleset" "firewall" {
  for_each = toset(var.domains)
  kind     = "zone"
  name     = "default"
  phase    = "http_request_firewall_custom"
  zone_id  = data.cloudflare_zone.domain[each.key].id
  rules {
    action = "skip"
    action_parameters {
      ruleset = "current"
    }
    description = "Allow GitHub flux API"
    enabled     = true
    expression  = "(http.host eq \"fluxhook.${each.key}\" and ip.geoip.asnum eq 36459)"
    logging {
      enabled = true
    }
  }
  rules {
    action = "skip"
    action_parameters {
      phases  = ["http_ratelimit", "http_request_firewall_managed", "http_request_sbfm"]
      ruleset = "current"
    }
    description = "Allow Specified paths"
    enabled     = true
    expression  = "(http.request.uri.path contains \"/feed/\") or (http.request.uri.path contains \"/api/\") or (http.user_agent eq \"Google-Calendar-Importer\") or (http.request.uri.path contains \"/image/\") or (http.request.uri.path contains \"/api2/json/\") or (http.user_agent contains \"Shields.io\") or (http.host eq \"nix-cache.${each.key}\")"
    logging {
      enabled = true
    }
  }
  rules {
    action      = "block"
    description = "Firewall rule to block countries"
    enabled     = true
    expression  = "(not ip.geoip.country in {\"SE\"})"
  }
  rules {
    action      = "block"
    description = "Firewall rule to block bots determined by CF"
    enabled     = true
    expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
  }
  rules {
    action      = "block"
    description = "Block AI Scrapers and Crawlers rule"
    enabled     = true
    expression  = "(cf.verified_bot_category eq \"AI Crawler\")"
  }
}
