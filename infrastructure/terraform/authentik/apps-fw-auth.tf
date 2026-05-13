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
      app_name                = "SABnzbd"
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
      app_name                = "Pinchflat"
      slug                    = "pinchflat"
      app_domain              = "pinchflat.${var.domain["external"]}"
      app_group               = "Downloads"
      access_groups           = [data.authentik_group.superuser.id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/pinchflat.png"
      outpost                 = "external"
    }
    librespeed = {
      app_name                = "LibreSpeed"
      slug                    = "librespeed"
      app_domain              = "speed.${var.domain["external"]}"
      app_group               = "Tools"
      access_groups           = [data.authentik_group.superuser.id, authentik_group.groups["users"].id]
      policy_engine_mode      = "any"
      authorization_flow_uuid = data.authentik_flow.default-provider-authorization-implicit-consent.id
      invalidation_flow_uuid  = data.authentik_flow.default-provider-invalidation-flow.id
      meta_icon               = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/librespeed.png"
      outpost                 = "external"
    }
  }
}
