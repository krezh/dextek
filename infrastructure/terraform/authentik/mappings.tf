data "authentik_property_mapping_provider_scope" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}

data "authentik_property_mapping_provider_scope" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}

data "authentik_property_mapping_provider_scope" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}

data "authentik_property_mapping_provider_scope" "offline_access" {
  managed = "goauthentik.io/providers/oauth2/scope-offline_access"
}

resource "authentik_property_mapping_provider_scope" "email" {
  name       = "Custom Email Scope"
  scope_name = "email"
  expression = <<-EOT
    return {
      "email": request.user.email,
      "email_verified": True
    }
  EOT
}
