module "echo_server" {
  source = "./modules/forward-auth-application"
  slug   = "echo_server"

  name      = "Echo Server"
  domain    = "echo-server.${var.domain}"
  app_group = "Infrastructure"

  access_groups = [resource.authentik_group.users.id]

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

  meta_icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/pgweb.png"
}
