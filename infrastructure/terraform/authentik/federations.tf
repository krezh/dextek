resource "authentik_source_plex" "plex" {
  name                = "Plex"
  slug                = "plex"
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = data.authentik_flow.default-source-authentication.id
  user_matching_mode  = "identifier"
  group_matching_mode = "identifier"
  allowed_servers = [
    "d4a31c1dc4c1c3e8931c7234eb31777fa176e264"
  ]
  allow_friends = false
  client_id     = "Authentik"
  plex_token    = "8WVQkVcyXBfrSv8zs2ZJ"
}
