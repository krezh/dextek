module "oauth_apps" {
  source = "./modules/oauth"
  domain = var.domain

  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  authentication_flow_id = authentik_flow.authentication.uuid
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = local.oauth2_scopes

  oauth_apps = {
    grafana = {
      app_group = "Monitoring"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["Grafana Admins"].id
      ]
      client_id          = module.app_secrets.secrets["grafana"].secrets["GRAFANA_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["grafana"].secrets["GRAFANA_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login/generic_oauth"]
    }
    mealie = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["mealie_admins"].id,
        authentik_group.groups["mealie_users"].id
      ]
      client_id          = module.app_secrets.secrets["mealie"].secrets["MEALIE_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["mealie"].secrets["MEALIE_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login"]
    }
    immich = {
      external   = true
      app_domain = "photos.${var.domain["external"]}"
      app_group  = "Media"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = module.app_secrets.secrets["immich"].secrets["IMMICH_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["immich"].secrets["IMMICH_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/login", "/user-settings"]
      redirect_uris = [
        "https://photos.${var.domain["internal"]}/auth/login",
        "https://photos.${var.domain["internal"]}/user-settings",
        "app.immich:///oauth-callback",
      ]
    }
    zipline = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = module.app_secrets.secrets["zipline"].secrets["ZIPLINE_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["zipline"].secrets["ZIPLINE_OAUTH_CLIENT_SECRET"].value
      property_mappings  = local.oauth2_scopes_offline_access
      redirect_uri_paths = ["/api/auth/oauth/oidc"]
      redirect_uris      = ["https://zipline.${var.domain["internal"]}/api/auth/oauth/oidc"]
    }
    kubernetes = {
      external   = true
      app_domain = var.domain["external"]
      app_group  = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id         = module.app_secrets.secrets["kubernetes"].secrets["KUBERNETES_OAUTH_CLIENT_ID"].value
      client_secret     = module.app_secrets.secrets["kubernetes"].secrets["KUBERNETES_OAUTH_CLIENT_SECRET"].value
      property_mappings = local.oauth2_scopes_offline_access
      redirect_uris = [
        "https://kauth.talos.plexuz.xyz/callback",
        "http://localhost:8080/callback"
      ]
      meta_launch_url = "blank://blank"
    }
    miniflux = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = module.app_secrets.secrets["miniflux"].secrets["MINIFLUX_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["miniflux"].secrets["MINIFLUX_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/oauth2/oidc/callback"]
      meta_description   = "Self-hosted RSS"
    }
    termix = {
      app_group = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = module.app_secrets.secrets["termix"].secrets["TERMIX_OAUTH_CLIENT_ID"].value
      client_secret      = module.app_secrets.secrets["termix"].secrets["TERMIX_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/users/oidc/callback"]
      meta_description   = "Server management platform"
    }
  }
}
