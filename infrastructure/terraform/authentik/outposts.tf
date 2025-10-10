
resource "authentik_outpost" "internal" {
  name               = "internal"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = module.fw-auth.internal_proxy_provider_ids
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
  protocol_providers = module.fw-auth.external_proxy_provider_ids
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
