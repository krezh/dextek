locals {
  tls_service = {
    "api-ssl" = 8729
    "www-ssl" = 443
  }
  disable_service = {
    "ftp"    = 21
    "telnet" = 23
  }
  enable_service = {
    "ssh"    = 22
    "winbox" = 8291
    "www"    = 80
    "api"    = 8728
  }
}

resource "routeros_ip_service" "tls" {
  for_each    = local.tls_service
  numbers     = each.key
  port        = each.value
  tls_version = "only-1.2"
  disabled    = false
}

resource "routeros_ip_service" "disabled" {
  for_each = local.disable_service
  numbers  = each.key
  port     = each.value
  disabled = true
}

resource "routeros_ip_service" "enabled" {
  for_each = local.enable_service
  numbers  = each.key
  port     = each.value
  disabled = false
}
