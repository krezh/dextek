locals {
  oauth_apps = [
    "dashbrr",
    "grafana",
    "headscale",
    "kyoo",
    "lubelog",
    "paperless",
    "portainer"
  ]
}

# Step 2: Parse the secrets using regex to extract client_id and client_secret
locals {
  applications = {
    dashbrr = {
      client_id     = module.onepassword_application["dashbrr"].fields["DASHBRR_CLIENT_ID"]
      client_secret = module.onepassword_application["dashbrr"].fields["DASHBRR_CLIENT_SECRET"]
      group         = authentik_group.monitoring.name
      icon_url      = "https://raw.githubusercontent.com/joryirving/home-ops/main/docs/src/assets/icons/dashbrr.png"
      redirect_uri  = "https://dashbrr.${var.domain}/api/auth/callback"
      launch_url    = "https://dashbrr.${var.domain}/api/auth/callback"
    },
    grafana = {
      client_id     = module.onepassword_application["grafana"].fields["GRAFANA_CLIENT_ID"]
      client_secret = module.onepassword_application["grafana"].fields["GRAFANA_CLIENT_SECRET"]
      group         = authentik_group.monitoring.name
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
      redirect_uri  = "https://grafana.${var.domain}/login/generic_oauth"
      launch_url    = "https://grafana.${var.domain}/login/generic_oauth"
    },
    headscale = {
      client_id     = module.onepassword_application["headscale"].fields["HEADSCALE_CLIENT_ID"]
      client_secret = module.onepassword_application["headscale"].fields["HEADSCALE_CLIENT_SECRET"]
      group         = authentik_group.infrastructure.name
      icon_url      = "https://raw.githubusercontent.com/joryirving/home-ops/main/docs/src/assets/icons/headscale.png"
      redirect_uri  = "https://headscale.${var.domain}/oidc/callback"
      launch_url    = "https://headscale.${var.domain}/"
    },
    kyoo = {
      client_id     = module.onepassword_application["kyoo"].fields["KYOO_CLIENT_ID"]
      client_secret = module.onepassword_application["kyoo"].fields["KYOO_CLIENT_SECRET"]
      group         = authentik_group.home.name
      icon_url      = "https://raw.githubusercontent.com/zoriya/Kyoo/master/icons/icon-256x256.png"
      redirect_uri  = "https://kyoo.${var.domain}/api/auth/logged/authentik"
      launch_url    = "https://kyoo.${var.domain}/api/auth/login/authentik?redirectUrl=https://kyoo.${var.domain}/login/callback"
    },
    lubelog = {
      client_id     = module.onepassword_application["lubelog"].fields["LUBELOG_CLIENT_ID"]
      client_secret = module.onepassword_application["lubelog"].fields["LUBELOG_CLIENT_SECRET"]
      group         = authentik_group.home.name
      icon_url      = "https://demo.lubelogger.com/defaults/lubelogger_icon_72.png"
      redirect_uri  = "https://lubelog.${var.domain}/Login/RemoteAuth"
      launch_url    = "https://lubelog.${var.domain}/Login/RemoteAuth"
    },
    paperless = {
      client_id     = module.onepassword_application["paperless"].fields["PAPERLESS_CLIENT_ID"]
      client_secret = module.onepassword_application["paperless"].fields["PAPERLESS_CLIENT_SECRET"]
      group         = authentik_group.home.name
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/paperless.png"
      redirect_uri  = "https://paperless.${var.domain}/accounts/oidc/authentik/login/callback/"
      launch_url    = "https://paperless.${var.domain}/"
    },
    portainer = {
      client_id     = module.onepassword_application["portainer"].fields["PORTAINER_CLIENT_ID"]
      client_secret = module.onepassword_application["portainer"].fields["PORTAINER_CLIENT_SECRET"]
      group         = authentik_group.infrastructure.name
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/portainer.png"
      redirect_uri  = "https://portainer.${var.domain}/"
      launch_url    = "https://portainer.${var.domain}/"
    }
  }
}

resource "authentik_provider_oauth2" "oauth2" {
  for_each              = local.applications
  name                  = each.key
  client_id             = each.value.client_id
  client_secret         = each.value.client_secret
  authorization_flow    = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow   = authentik_flow.authentication.uuid
  invalidation_flow     = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings     = data.authentik_property_mapping_provider_scope.oauth2.ids
  access_token_validity = "hours=4"
  signing_key           = data.authentik_certificate_key_pair.generated.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = each.value.redirect_uri,
    }
  ]
}

resource "authentik_application" "application" {
  for_each           = local.applications
  name               = title(each.key)
  slug               = each.key
  protocol_provider  = authentik_provider_oauth2.oauth2[each.key].id
  group              = each.value.group
  open_in_new_tab    = true
  meta_icon          = each.value.icon_url
  meta_launch_url    = each.value.launch_url
  policy_engine_mode = "all"
}
