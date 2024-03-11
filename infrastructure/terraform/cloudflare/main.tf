data "http" "ipv4" {
  url = "https://ipv4.icanhazip.com"
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

data "cloudflare_zone" "domain" {
  for_each = toset(var.domains)
  name     = each.value
}
