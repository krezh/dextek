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
        authentik_group.grafana_admins.id
      ]
      client_id          = data.infisical_secrets.grafana.secrets["GRAFANA_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.grafana.secrets["GRAFANA_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login/generic_oauth"]
    }
    mealie = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        resource.authentik_group.mealie_admins.id,
        resource.authentik_group.mealie_users.id
      ]
      client_id          = data.infisical_secrets.mealie.secrets["MEALIE_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.mealie.secrets["MEALIE_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/login"]
    }
    immich = {
      external   = true
      app_domain = "photos.${var.domain["external"]}"
      app_group  = "Media"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.immich.secrets["IMMICH_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.immich.secrets["IMMICH_OAUTH_CLIENT_SECRET"].value
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
        authentik_group.users.id
      ]
      client_id          = data.infisical_secrets.zipline.secrets["ZIPLINE_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.zipline.secrets["ZIPLINE_OAUTH_CLIENT_SECRET"].value
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
      client_id         = data.infisical_secrets.kubernetes.secrets["KUBERNETES_OAUTH_CLIENT_ID"].value
      client_secret     = data.infisical_secrets.kubernetes.secrets["KUBERNETES_OAUTH_CLIENT_SECRET"].value
      property_mappings = local.oauth2_scopes_offline_access
      redirect_uris = [
        "https://kauth.talos.plexuz.xyz/callback",
        "http://localhost:8080/callback"
      ]
      meta_launch_url = "blank://blank"
    }
    karakeep = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        resource.authentik_group.users.id
      ]
      client_id          = data.infisical_secrets.karakeep.secrets["KARAKEEP_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.karakeep.secrets["KARAKEEP_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/api/auth/callback/custom"]
      meta_description   = "A self-hostable bookmark-everything app (links, notes and images) with AI-based automatic tagging and full text search"
    }
    wakapi = {
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id
      ]
      client_id          = data.infisical_secrets.wakapi.secrets["WAKAPI_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.wakapi.secrets["WAKAPI_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/oidc/authentik/callback"]
      meta_description   = "Self-hosted WakaTime-compatible backend for coding statistics"
    }
    pangolin = {
      external  = true
      app_group = "Infrastructure"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.users.id
      ]
      client_id          = data.infisical_secrets.pangolin.secrets["PANGOLIN_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.pangolin.secrets["PANGOLIN_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/auth/idp/1/oidc/callback"]
      meta_description   = "Self-hosted Cloudflare Tunnels"
    }
    miniflux = {
      external  = true
      app_group = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        authentik_group.users.id
      ]
      client_id          = data.infisical_secrets.miniflux.secrets["MINIFLUX_OAUTH_CLIENT_ID"].value
      client_secret      = data.infisical_secrets.miniflux.secrets["MINIFLUX_OAUTH_CLIENT_SECRET"].value
      redirect_uri_paths = ["/oauth2/oidc/callback"]
      meta_description   = "Self-hosted RSS"
    }
  }
}
