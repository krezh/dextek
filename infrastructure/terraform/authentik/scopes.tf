## OAuth scopes
locals {
  oauth2_scopes = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    authentik_property_mapping_provider_scope.email.id,
  ]

  oauth2_scopes_offline_access = concat(
    local.oauth2_scopes,
    [data.authentik_property_mapping_provider_scope.offline_access.id]
  )
}
