resource "routeros_system_certificate" "https_cert" {
  name        = "HTTPS-Cert"
  common_name = acme_certificate.certificate.certificate_domain
  import {
    key_file_content  = acme_certificate.certificate.private_key_pem
    cert_file_content = acme_certificate.certificate.certificate_pem
  }
}
