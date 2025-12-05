module "fw-auth" {
  source = "./modules/fw-auth"
  forward_auth_apps = {
    echo_server = {
      app_name                = "Echo Server"
      slug                    = "echo_server"
      app_domain              = "echo-server.${var.domain["external"]}"
      app_group               = "Infrastructure"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/web-check.png"
      outpost                 = "external"
    }
    sonarr = {
      app_name                = "Sonarr"
      slug                    = "sonarr"
      app_domain              = "sonarr.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sonarr.png"
      outpost                 = "external"
    }
    radarr = {
      app_name                = "Radarr"
      slug                    = "radarr"
      app_domain              = "radarr.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/radarr.png"
      outpost                 = "external"
    }
    prowlarr = {
      app_name                = "Prowlarr"
      slug                    = "prowlarr"
      app_domain              = "prowlarr.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/prowlarr.png"
      outpost                 = "external"
    }
    bazarr = {
      app_name                = "Bazarr"
      slug                    = "bazarr"
      app_domain              = "bazarr.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/bazarr.png"
      outpost                 = "external"
    }
    maintainerr = {
      app_name                = "Maintainerr"
      slug                    = "maintainerr"
      app_domain              = "maintainerr.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/maintainerr.png"
      outpost                 = "external"
    }
    sabnzbd = {
      app_name                = "Sabnzbd"
      slug                    = "sabnzbd"
      app_domain              = "sab.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/sabnzbd.png"
      outpost                 = "external"
    }
    nzbget = {
      app_name                = "NZBGet"
      slug                    = "nzbget"
      app_domain              = "nzbget.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nzbget.png"
      outpost                 = "external"
    }
    changedetection = {
      app_name                = "Changedetection"
      slug                    = "changedetection"
      app_domain              = "changedetection.${var.domain["external"]}"
      app_group               = "Tools"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/changedetection.png"
      outpost                 = "external"
    }
    homepage = {
      app_name                = "Homepage"
      slug                    = "homepage"
      app_domain              = "homepage.${var.domain["external"]}"
      app_group               = ""
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
      outpost                 = "external"
    }
    home = {
      app_name                = "Home"
      slug                    = "home"
      app_domain              = var.domain["external"]
      app_group               = ""
      access_groups           = [resource.authentik_group.users.id, data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png"
      outpost                 = "external"
    }
    homeassistant = {
      app_name                = "Home Assistant"
      slug                    = "homeassistant"
      app_domain              = "hass.${var.domain["external"]}"
      app_group               = "Home"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/home-assistant.png"
      outpost                 = "external"
    }
    pinchflat = {
      app_name                = "pinchflat"
      slug                    = "pinchflat"
      app_domain              = "pinchflat.${var.domain["internal"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/pinchflat.png"
      outpost                 = "internal"
    }
  }
}
