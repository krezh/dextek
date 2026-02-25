resource "acme_registration" "reg" {
  email_address = data.doppler_secrets.prd_routeros.map.LETSENCRYPT_EMAIL
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "yggdrasil.lan.plexuz.xyz"
  subject_alternative_names = [
    "yggdrasil.srv.plexuz.xyz",
    "mikrotik.lan.plexuz.xyz",
    "mikrotik.srv.plexuz.xyz",
  ]
  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_DNS_API_TOKEN = "${data.doppler_secrets.prd_routeros.map.CLOUDFLARE_API_TOKEN}"
    }
  }
}
