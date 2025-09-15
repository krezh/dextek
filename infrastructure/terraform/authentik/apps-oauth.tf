module "grafana" {
  source = "./modules/oidc-application"
  slug   = "grafana"

  name       = "Grafana"
  app_domain = "grafana.${var.domain["internal"]}"
  app_group  = "Monitoring"

  access_groups = [data.authentik_group.superuser.id, authentik_group.grafana_admins.id]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.GRAFANA)["GRAFANA_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://grafana.${var.domain["internal"]}/login/generic_oauth"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/grafana.png"
  meta_launch_url = "https://grafana.${var.domain["internal"]}"
}

module "minio" {
  source = "./modules/oidc-application"
  slug   = "minio"

  name       = "Minio"
  app_domain = "minio.${var.domain["external"]}"
  app_group  = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]


  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.MINIO)["MINIO_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.MINIO)["MINIO_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = ["https://minio.int.${var.domain["external"]}/oauth_callback"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/minio.png"
  meta_launch_url = "https://minio.int.${var.domain["external"]}"
}

module "mealie" {
  source = "./modules/oidc-application"
  slug   = "mealie"

  name       = "Mealie"
  app_domain = "mealie.${var.domain["external"]}"
  app_group  = "Tools"

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

  redirect_uris = ["https://mealie.${var.domain["external"]}/login"]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mealie.png"
  meta_launch_url = "https://mealie.${var.domain["external"]}"
}

module "immich" {
  source = "./modules/oidc-application"
  slug   = "immich"

  name       = "Immich"
  app_domain = "photos.${var.domain["external"]}"
  app_group  = "Tools"

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
    "https://photos.${var.domain["external"]}/auth/login",
    "https://photos.${var.domain["external"]}/user-settings",
    "https://photos.${var.domain["internal"]}/auth/login",
    "https://photos.${var.domain["internal"]}/user-settings",
    "app.immich:///oauth-callback"
  ]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/immich.png"
  meta_launch_url = "https://photos.${var.domain["external"]}"
}

module "zipline" {
  source = "./modules/oidc-application"
  slug   = "zipline"

  name       = "Zipline"
  app_domain = "zipline.${var.domain["external"]}"
  app_group  = "Tools"

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
    "https://zipline.${var.domain["external"]}/api/auth/oauth/oidc"
  ]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/zipline.png"
  meta_launch_url = "https://zipline.${var.domain["external"]}"
}

module "kubernetes" {
  source = "./modules/oidc-application"
  slug   = "kubernetes"

  name       = "Kubernetes"
  app_domain = var.domain["external"]
  app_group  = "Infrastructure"

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
    "https://headlamp.${var.domain["internal"]}/oidc-callback"
  ]

  access_token_validity = "hours=4"

  meta_icon       = ""
  meta_launch_url = "blank://blank"
}

module "karakeep" {
  source = "./modules/oidc-application"
  slug   = "karakeep"

  name       = "Karakeep"
  app_domain = "karakeep.${var.domain["external"]}"
  app_group  = "Tools"

  access_groups = [
    data.authentik_group.superuser.id,
    resource.authentik_group.users.id
  ]

  client_id     = jsondecode(data.doppler_secrets.tf_authentik.map.KARAKEEP)["KARAKEEP_OAUTH_CLIENT_ID"]
  client_secret = jsondecode(data.doppler_secrets.tf_authentik.map.KARAKEEP)["KARAKEEP_OAUTH_CLIENT_SECRET"]

  authentication_flow_id = authentik_flow.authentication.uuid
  authorization_flow_id  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow_id   = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings      = data.authentik_property_mapping_provider_scope.oauth2.ids

  redirect_uris = [
    "https://karakeep.${var.domain["external"]}/api/auth/callback/custom"
  ]

  access_token_validity = "hours=4"

  meta_icon       = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/karakeep.png"
  meta_launch_url = "https://karakeep.${var.domain["external"]}"
}
