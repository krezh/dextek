module "oauth_apps" {
  source = "./modules/oauth"

  oauth_apps = {
    grafana = {
      name                   = "Grafana"
      slug                   = "grafana"
      app_domain             = "grafana.${var.domain["internal"]}"
      app_group              = "Monitoring"
      access_groups          = [data.authentik_group.superuser.id, authentik_group.grafana_admins.id]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids
      redirect_uris          = ["https://grafana.${var.domain["internal"]}/login/generic_oauth"]
      meta_icon              = "dashboard-icons"
      meta_launch_url        = "https://grafana.${var.domain["internal"]}"
    }
    mealie = {
      name       = "Mealie"
      slug       = "mealie"
      app_domain = "mealie.${var.domain["external"]}"
      app_group  = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        resource.authentik_group.mealie_admins.id,
        resource.authentik_group.mealie_users.id
      ]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.MEALIE)["MEALIE_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.MEALIE)["MEALIE_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids
      redirect_uris          = ["https://mealie.${var.domain["external"]}/login"]
      meta_icon              = "dashboard-icons"
      meta_launch_url        = "https://mealie.${var.domain["external"]}"
    }
    immich = {
      name                   = "Immich"
      slug                   = "immich"
      app_domain             = "photos.${var.domain["external"]}"
      app_group              = "Tools"
      access_groups          = [data.authentik_group.superuser.id]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.IMMICH)["IMMICH_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.IMMICH)["IMMICH_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids
      redirect_uris = [
        "https://photos.${var.domain["external"]}/auth/login",
        "https://photos.${var.domain["external"]}/user-settings",
        "https://photos.${var.domain["internal"]}/auth/login",
        "https://photos.${var.domain["internal"]}/user-settings",
        "app.immich:///oauth-callback"
      ]
      meta_icon       = "dashboard-icons"
      meta_launch_url = "https://photos.${var.domain["external"]}"
    }
    zipline = {
      name                   = "Zipline"
      slug                   = "zipline"
      app_domain             = "zipline.${var.domain["external"]}"
      app_group              = "Tools"
      access_groups          = [data.authentik_group.superuser.id]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.ZIPLINE)["ZIPLINE_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.ZIPLINE)["ZIPLINE_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2_offline_access.ids
      redirect_uris          = ["https://zipline.${var.domain["external"]}/api/auth/oauth/oidc"]
      meta_icon              = "dashboard-icons"
      meta_launch_url        = "https://zipline.${var.domain["external"]}"
    }
    kubernetes = {
      name                   = "Kubernetes"
      slug                   = "kubernetes"
      app_domain             = var.domain["external"]
      app_group              = "Infrastructure"
      access_groups          = [data.authentik_group.superuser.id]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.KUBERNETES)["KUBERNETES_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.KUBERNETES)["KUBERNETES_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids
      redirect_uris          = ["https://headlamp.${var.domain["internal"]}/oidc-callback", "https://kauth.talos.plexuz.xyz/callback"]
      meta_icon              = ""
      meta_launch_url        = "blank://blank"
    }
    karakeep = {
      name       = "Karakeep"
      slug       = "karakeep"
      app_domain = "karakeep.${var.domain["external"]}"
      app_group  = "Tools"
      access_groups = [
        data.authentik_group.superuser.id,
        resource.authentik_group.users.id
      ]
      client_id              = jsondecode(data.doppler_secrets.tf_authentik.map.KARAKEEP)["KARAKEEP_OAUTH_CLIENT_ID"]
      client_secret          = jsondecode(data.doppler_secrets.tf_authentik.map.KARAKEEP)["KARAKEEP_OAUTH_CLIENT_SECRET"]
      authentication_flow_id = authentik_flow.authentication.uuid
      authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
      property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids
      redirect_uris          = ["https://karakeep.${var.domain["external"]}/api/auth/callback/custom"]
      meta_icon              = "dashboard-icons"
      meta_launch_url        = "https://karakeep.${var.domain["external"]}"
      meta_description       = "A self-hostable bookmark-everything app (links, notes and images) with AI-based automatic tagging and full text search"
    }
  }
}
