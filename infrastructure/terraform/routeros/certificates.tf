resource "routeros_system_certificate" "root_ca" {
  name        = "Root-CA"
  common_name = "RootCA"
  key_usage   = ["key-cert-sign", "crl-sign"]
  days_valid  = 3650
  trusted     = true
  // Sign Root CA.
  sign {
  }
}

// digitalSignature: Used for entity and data origin authentication with integrity.
// keyEncipherment:  Used to encrypt symmetric key, which is then transferred to target.
// keyAgreement:     Enables use of key agreement to establish symmetric key with target. 

resource "routeros_system_certificate" "https_cert" {
  name             = "HTTPS-Cert"
  common_name      = "mikrotik"
  key_size         = "2048"
  key_usage        = ["digital-signature", "key-encipherment", "tls-server", "key-agreement"]
  subject_alt_name = "DNS:mikrotik.usr.int.plexuz.xyz,IP:192.168.1.35"
  days_valid       = 3650
  sign {
    ca = routeros_system_certificate.root_ca.name
  }
}
