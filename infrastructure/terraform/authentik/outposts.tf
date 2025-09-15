locals {
  internal_proxy_provider_ids = [
    module.pgweb.proxy_provider_id,
    module.n8n.proxy_provider_id,
    module.pinchflat.proxy_provider_id
  ]

  external_proxy_provider_ids = [
    module.echo_server.proxy_provider_id,
    module.sonarr.proxy_provider_id,
    module.radarr.proxy_provider_id,
    module.jdownloader2.proxy_provider_id,
    module.bazarr.proxy_provider_id,
    module.maintainerr.proxy_provider_id,
    module.prowlarr.proxy_provider_id,
    module.sabnzbd.proxy_provider_id,
    module.whisparr.proxy_provider_id,
    module.changedetection.proxy_provider_id,
    module.wallos.proxy_provider_id,
    module.homepage.proxy_provider_id,
    module.home.proxy_provider_id,
    module.homeassistant.proxy_provider_id,
    module.checkrr.proxy_provider_id
  ]
}

resource "authentik_outpost" "internal" {
  name               = "internal"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = local.internal_proxy_provider_ids
  config = jsonencode({
    "log_level"                      = "info"
    "authentik_host"                 = "https://sso.${var.domain["external"]}/"
    "authentik_host_insecure"        = false
    "authentik_host_browser"         = ""
    "refresh_interval"               = "minutes=5"
    "docker_labels"                  = null
    "docker_network"                 = null
    "docker_map_ports"               = true
    "container_image"                = null
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "auth"
    "object_naming_template"         = "ak-outpost-%(name)s"
    "kubernetes_json_patches"        = null
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_image_pull_secrets"  = []
    "kubernetes_ingress_class_name"  = "nginx-internal"
    "kubernetes_disabled_components" = ["ingress", "traefik middleware"]
    "kubernetes_ingress_annotations" = {}
    "kubernetes_ingress_secret_name" = "authentik-outpost-tls"
    "kubernetes_httproute_parent_refs" = [
      {
        name        = "gateway-internal"
        namespace   = "network"
        sectionName = "https"
      }
    ]
  })
}

resource "authentik_outpost" "external" {
  name               = "external"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = local.external_proxy_provider_ids
  config = jsonencode({
    "log_level"                      = "info"
    "authentik_host"                 = "https://sso.${var.domain["external"]}/"
    "authentik_host_insecure"        = false
    "authentik_host_browser"         = ""
    "refresh_interval"               = "minutes=5"
    "docker_labels"                  = null
    "docker_network"                 = null
    "docker_map_ports"               = true
    "container_image"                = null
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "auth"
    "object_naming_template"         = "ak-outpost-%(name)s"
    "kubernetes_json_patches"        = null
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_image_pull_secrets"  = []
    "kubernetes_ingress_class_name"  = "nginx-external"
    "kubernetes_disabled_components" = ["ingress", "traefik middleware"]
    "kubernetes_ingress_annotations" = {}
    "kubernetes_ingress_secret_name" = "authentik-outpost-tls"
    "kubernetes_httproute_parent_refs" = [
      {
        name        = "gateway-external"
        namespace   = "network"
        sectionName = "https"
      }
    ]
  })
}
