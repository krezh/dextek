module "grafana" {
  source = "./modules/oidc-application"
  slug   = "grafana"

  name      = "Grafana"
  domain    = "grafana.talos.${var.domain}"
  app_group = "Monitoring"

  access_groups = [data.authentik_group.superuser.id]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://grafana.talos.${var.domain}/login/generic_oauth"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/grafana.png"
  meta_launch_url = "https://grafana.talos.${var.domain}"
}

module "minio" {
  source = "./modules/oidc-application"
  slug   = "minio"

  name      = "Minio"
  domain    = "minio.${var.domain}"
  app_group = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]


  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.MINIO)["MINIO_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.MINIO)["MINIO_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://minio.int.${var.domain}/oauth_callback"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/minio.png"
  meta_launch_url = "https://minio.int.${var.domain}"
}

module "mealie" {
  source = "./modules/oidc-application"
  slug   = "mealie"

  name      = "Mealie"
  domain    = "mealie.${var.domain}"
  app_group = "Tools"

  access_groups = [
    data.authentik_group.superuser.id,
    resource.authentik_group.mealie_admins.id,
    resource.authentik_group.mealie_users.id
  ]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.MEALIE)["MEALIE_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.MEALIE)["MEALIE_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://mealie.${var.domain}/login"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mealie.png"
  meta_launch_url = "https://mealie.${var.domain}"
}

module "immich" {
  source = "./modules/oidc-application"
  slug   = "immich"

  name      = "Immich"
  domain    = "photos.${var.domain}"
  app_group = "Tools"

  access_groups = [
    data.authentik_group.superuser.id
  ]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.IMMICH)["IMMICH_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.IMMICH)["IMMICH_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = [
    "https://photos.${var.domain}/auth/login",
    "https://photos.${var.domain}/user-settings",
    "https://photos.talos.${var.domain}/auth/login",
    "https://photos.talos.${var.domain}/user-settings",
    "app.immich:///oauth-callback"
  ]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/immich.png"
  meta_launch_url = "https://photos.${var.domain}"
}

module "zipline" {
  source = "./modules/oidc-application"
  slug   = "zipline"

  name      = "Zipline"
  domain    = "zipline.${var.domain}"
  app_group = "Tools"

  access_groups = [
    data.authentik_group.superuser.id
  ]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.ZIPLINE)["ZIPLINE_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.ZIPLINE)["ZIPLINE_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2_offline_access.ids

  redirect_uris = [
    "https://zipline.${var.domain}/api/auth/oauth/oidc"
  ]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/zipline.png"
  meta_launch_url = "https://zipline.${var.domain}"
}

module "kubernetes" {
  source = "./modules/oidc-application"
  slug   = "kubernetes"

  name      = "Kubernetes"
  domain    = var.domain
  app_group = "Infrastructure"

  access_groups = [
    data.authentik_group.superuser.id
  ]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.KUBERNETES)["KUBERNETES_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.KUBERNETES)["KUBERNETES_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = [
    "https://headlamp.talos.${var.domain}/oidc-callback"
  ]

  access_token_validity = "hours=4"

  meta_icon       = ""
  meta_launch_url = "blank://blank"
}
