module "echo_server" {
  source = "./modules/forward-auth-application"
  slug   = "echo_server"

  name      = "Echo Server"
  domain    = "echo-server.${var.domain}"
  app_group = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/web-check.png"
}

module "echo_server_internal" {
  source = "./modules/forward-auth-application"
  slug   = "echo_server_internal"

  name      = "Echo Server Internal"
  domain    = "echo-server.talos.${var.domain}"
  app_group = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/web-check.png"
}

module "pgweb" {
  source = "./modules/forward-auth-application"
  slug   = "pgweb"

  name      = "PGWeb"
  domain    = "pgweb.talos.${var.domain}"
  app_group = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
}

module "sonarr" {
  source = "./modules/forward-auth-application"
  slug   = "sonarr"

  name      = "Sonarr"
  domain    = "sonarr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sonarr.png"
}

module "radarr" {
  source = "./modules/forward-auth-application"
  slug   = "radarr"

  name      = "Radarr"
  domain    = "radarr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/radarr.png"
}

module "prowlarr" {
  source = "./modules/forward-auth-application"
  slug   = "prowlarr"

  name      = "Prowlarr"
  domain    = "prowlarr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/prowlarr.png"
}

module "jdownloader2" {
  source = "./modules/forward-auth-application"
  slug   = "jdownloader2"

  name      = "JDownloader2"
  domain    = "jd.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jdownloader2.png"
}

module "bazarr" {
  source = "./modules/forward-auth-application"
  slug   = "bazarr"

  name      = "Bazarr"
  domain    = "bazarr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/bazarr.png"
}

module "maintainerr" {
  source = "./modules/forward-auth-application"
  slug   = "maintainerr"

  name      = "Maintainerr"
  domain    = "maintainerr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/maintainerr.png"
}

module "sabnzbd" {
  source = "./modules/forward-auth-application"
  slug   = "sabnzbd"

  name      = "Sabnzbd"
  domain    = "sab.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sabnzbd.png"
}

module "whisparr" {
  source = "./modules/forward-auth-application"
  slug   = "whisparr"

  name      = "Whisparr"
  domain    = "whisparr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/whisparr.png"
}

module "changedetection" {
  source = "./modules/forward-auth-application"
  slug   = "changedetection"

  name      = "Changedetection"
  domain    = "changedetection.${var.domain}"
  app_group = "Tools"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/changedetection.png"
}

module "wallos" {
  source = "./modules/forward-auth-application"
  slug   = "wallos"

  name      = "Wallos"
  domain    = "wallos.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/wallos.png"
}

module "homepage" {
  source = "./modules/forward-auth-application"
  slug   = "homepage"

  name      = "Homepage"
  domain    = "homepage.${var.domain}"
  app_group = ""

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
}

module "home" {
  source = "./modules/forward-auth-application"
  slug   = "home"

  name      = "Home"
  domain    = var.domain
  app_group = ""

  access_groups = [resource.authentik_group.users.id, data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
}

module "homeassistant" {
  source = "./modules/forward-auth-application"
  slug   = "homeassistant"

  name      = "Home Assistant"
  domain    = "hass.${var.domain}"
  app_group = "Home"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/home-assistant.png"
}

module "n8n" {
  source = "./modules/forward-auth-application"
  slug   = "n8n"

  name      = "n8n"
  domain    = "n8n.talos.${var.domain}"
  app_group = "Tools"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/n8n.png"
}

module "checkrr" {
  source = "./modules/forward-auth-application"
  slug   = "checkrr"

  name      = "checkrr"
  domain    = "checkrr.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  #meta_icon = ""
}

module "pinchflat" {
  source = "./modules/forward-auth-application"
  slug   = "pinchflat"

  name      = "pinchflat"
  domain    = "pinchflat.talos.${var.domain}"
  app_group = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/pinchflat.png"
}
