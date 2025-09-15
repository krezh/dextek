module "echo_server" {
  source = "./modules/forward-auth-application"
  slug   = "echo_server"

  name       = "Echo Server"
  app_domain = "echo-server.${var.domain["external"]}"
  app_group  = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/web-check.png"
}

module "pgweb" {
  source = "./modules/forward-auth-application"
  slug   = "pgweb"

  name       = "PGWeb"
  app_domain = "pgweb.${var.domain["internal"]}"
  app_group  = "Infrastructure"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
}

module "sonarr" {
  source = "./modules/forward-auth-application"
  slug   = "sonarr"

  name       = "Sonarr"
  app_domain = "sonarr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sonarr.png"
}

module "radarr" {
  source = "./modules/forward-auth-application"
  slug   = "radarr"

  name       = "Radarr"
  app_domain = "radarr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/radarr.png"
}

module "prowlarr" {
  source = "./modules/forward-auth-application"
  slug   = "prowlarr"

  name       = "Prowlarr"
  app_domain = "prowlarr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/prowlarr.png"
}

module "jdownloader2" {
  source = "./modules/forward-auth-application"
  slug   = "jdownloader2"

  name       = "JDownloader2"
  app_domain = "jd.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jdownloader2.png"
}

module "bazarr" {
  source = "./modules/forward-auth-application"
  slug   = "bazarr"

  name       = "Bazarr"
  app_domain = "bazarr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/bazarr.png"
}

module "maintainerr" {
  source = "./modules/forward-auth-application"
  slug   = "maintainerr"

  name       = "Maintainerr"
  app_domain = "maintainerr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/maintainerr.png"
}

module "sabnzbd" {
  source = "./modules/forward-auth-application"
  slug   = "sabnzbd"

  name       = "Sabnzbd"
  app_domain = "sab.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sabnzbd.png"
}

module "whisparr" {
  source = "./modules/forward-auth-application"
  slug   = "whisparr"

  name       = "Whisparr"
  app_domain = "whisparr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/whisparr.png"
}

module "changedetection" {
  source = "./modules/forward-auth-application"
  slug   = "changedetection"

  name       = "Changedetection"
  app_domain = "changedetection.${var.domain["external"]}"
  app_group  = "Tools"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/changedetection.png"
}

module "wallos" {
  source = "./modules/forward-auth-application"
  slug   = "wallos"

  name       = "Wallos"
  app_domain = "wallos.${var.domain["external"]}"
  app_group  = "Tools"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/wallos.png"
}

module "homepage" {
  source = "./modules/forward-auth-application"
  slug   = "homepage"

  name       = "Homepage"
  app_domain = "homepage.${var.domain["external"]}"
  app_group  = ""

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
}

module "home" {
  source = "./modules/forward-auth-application"
  slug   = "home"

  name       = "Home"
  app_domain = var.domain["external"]
  app_group  = ""

  access_groups = [resource.authentik_group.users.id, data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
}

module "homeassistant" {
  source = "./modules/forward-auth-application"
  slug   = "homeassistant"

  name       = "Home Assistant"
  app_domain = "hass.${var.domain["external"]}"
  app_group  = "Home"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/home-assistant.png"
}

module "n8n" {
  source = "./modules/forward-auth-application"
  slug   = "n8n"

  name       = "n8n"
  app_domain = "n8n.${var.domain["internal"]}"
  app_group  = "Tools"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/n8n.png"
}

module "checkrr" {
  source = "./modules/forward-auth-application"
  slug   = "checkrr"

  name       = "checkrr"
  app_domain = "checkrr.${var.domain["external"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  #meta_icon = ""
}

module "pinchflat" {
  source = "./modules/forward-auth-application"
  slug   = "pinchflat"

  name       = "pinchflat"
  app_domain = "pinchflat.${var.domain["internal"]}"
  app_group  = "Downloads"

  access_groups = [data.authentik_group.superuser.id]

  policy_engine_mode      = "any"
  authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id

  meta_icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/pinchflat.png"
}
