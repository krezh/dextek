resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  for_each = toset(var.domains)
  zone_id  = data.cloudflare_zone.domain[each.key].id
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "high"
    brotli                   = "on"
    browser_cache_ttl        = 0
    # minify {
    #   css  = "on"
    #   js   = "on"
    #   html = "on"
    # }
    rocket_loader       = "on"
    always_online       = "off"
    development_mode    = "off"
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    security_header {
      enabled = true
    }
  }
}
