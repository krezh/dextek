data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_brand" "plexuz" {
  domain              = var.domain
  branding_title      = "Plexuz"
  branding_logo       = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon    = "/static/dist/assets/icons/icon.png"
  branding_custom_css = file("branding/plexuz.css")

  flow_authentication = authentik_flow.authentication.uuid
  flow_invalidation   = authentik_flow.invalidation.uuid
  flow_user_settings  = authentik_flow.user-settings.uuid
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "local"
  local = true
}
