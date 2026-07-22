module "oauth_apps" {
  source = "./modules/oauth"
  domain = var.domain

  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  authentication_flow_id = authentik_flow.authentication.uuid
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = local.oauth2_scopes

  oauth_apps = {
    grafana = {
      app_group  = "Monitoring"
      app_domain = "grafana.${var.domain}"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["Grafana Admins"].id
      ]
      client_id          = data.infisical_secrets.grafana.secrets["GRAFANA_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.grafana.secrets["GRAFANA_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login/generic_oauth"]
    }
    mealie = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["mealie_admins"].id,
        authentik_group.groups["mealie_users"].id
      ]
      client_id          = data.infisical_secrets.mealie.secrets["MEALIE_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.mealie.secrets["MEALIE_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login"]
    }
    immich = {
      app_domain = "photos.${var.domain}"
      app_group  = "Media"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.immich.secrets["IMMICH_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.immich.secrets["IMMICH_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/login", "/user-settings"]
      redirect_uris      = ["app.immich:///oauth-callback", ]
    }
    zipline = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = data.infisical_secrets.zipline.secrets["ZIPLINE_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.zipline.secrets["ZIPLINE_OAUTH_CLIENT_SECRET"].value
      property_mappings  = local.oauth2_scopes_offline_access
      redirect_uri_paths = ["/api/auth/oauth/oidc"]
    }
    kubernetes = {
      app_domain = var.domain
      app_group  = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id         = data.infisical_secrets.kubernetes.secrets["KUBERNETES_OAUTH_CLIENT_ID"].value
      client_secret     = data.infisical_secrets.kubernetes.secrets["KUBERNETES_OAUTH_CLIENT_SECRET"].value
      property_mappings = local.oauth2_scopes_offline_access
      redirect_uris = [
        "https://kauth.plexuz.xyz/callback",
        "https://roder.plexuz.xyz/auth/callback",
        "http://localhost:8080/callback",
        "http://localhost:8080/auth/callback"
      ]
      meta_launch_url = "blank://blank"
    }
    miniflux = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = data.infisical_secrets.miniflux.secrets["MINIFLUX_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.miniflux.secrets["MINIFLUX_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/oauth2/oidc/callback"]
      meta_description   = "Self-hosted RSS"
    }
    termix = {
      app_group = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.termix.secrets["TERMIX_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.termix.secrets["TERMIX_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/users/oidc/callback"]
      meta_description   = "Server management platform"
    }
    profilarr = {
      app_group = "Downloads"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.profilarr.secrets["PROFILARR_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.profilarr.secrets["PROFILARR_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/oidc/callback"]
      meta_description   = ""
    }
    papra = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = data.infisical_secrets.papra.secrets["PAPRA_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.papra.secrets["PAPRA_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/api/auth/oauth2/callback/authentik"]
    }
    qui = {
      app_group = "Downloads"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.qui.secrets["QUI_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.qui.secrets["QUI_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/api/auth/oidc/callback"]
      meta_description   = "qBittorrent management UI"
    }
    nixsmith = {
      app_group = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.nixsmith.secrets["NIXSMITH_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.nixsmith.secrets["NIXSMITH_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/callback"]
      meta_description   = "Distributed Nix build system"
    }
    gotify = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.groups["users"].id
      ]
      client_id          = data.infisical_secrets.gotify.secrets["GOTIFY_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.gotify.secrets["GOTIFY_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/oidc/callback"]
      redirect_uris      = ["gotify://oidc/callback"]
      meta_description   = "Notification server"
    }
  }
}
