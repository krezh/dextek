
resource "authentik_outpost" "internal" {
  name               = "internal"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = module.fw-auth.internal_proxy_provider_ids
  config = jsonencode({
    "log_level"                      = "info"
    "authentik_host"                 = "https://sso.${var.domain["external"]}/"
    "authentik_host_insecure"        = false
    "refresh_interval"               = "minutes=5"
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "auth"
    "object_naming_template"         = "ak-outpost-%(name)s"
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_disabled_components" = ["ingress", "traefik middleware"]
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
    "refresh_interval"               = "minutes=5"
    "kubernetes_replicas"            = 1
    "kubernetes_namespace"           = "auth"
    "object_naming_template"         = "ak-outpost-%(name)s"
    "kubernetes_service_type"        = "ClusterIP"
    "kubernetes_disabled_components" = ["ingress", "traefik middleware"]
    "kubernetes_httproute_parent_refs" = [
      {
        name        = "gateway-external"
        namespace   = "network"
        sectionName = "https"
      }
    ]
  })
}
