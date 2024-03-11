resource "opnsense_unbound_host_override" "talos_api" {
  enabled     = true
  description = "Talos Api Loadbalancer"

  hostname = "talos"
  domain   = "k8s.plexuz.xyz"
  server   = "192.168.20.5"
}

resource "opnsense_unbound_host_override" "s3" {
  enabled     = true
  description = "Minio S3 Api"

  hostname = "s3"
  domain   = "int.plexuz.xyz"
  server   = "192.168.20.2"
}

resource "opnsense_unbound_host_override" "minio" {
  enabled     = true
  description = "Minio S3 Webgui"

  hostname = "minio"
  domain   = "int.plexuz.xyz"
  server   = "192.168.20.2"
}

resource "opnsense_unbound_host_override" "harbor" {
  enabled     = true
  description = "Harbor Registry"

  hostname = "harbor"
  domain   = "int.plexuz.xyz"
  server   = "192.168.20.2"
}


resource "opnsense_unbound_host_override" "matchbox" {
  enabled     = true
  description = "Matchbox"

  hostname = "matchbox"
  domain   = "int.plexuz.xyz"
  server   = "192.168.1.52"
}


resource "opnsense_unbound_host_override" "zot" {
  enabled     = true
  description = "ZOT Pull Through Cache"

  hostname = "zot"
  domain   = "int.plexuz.xyz"
  server   = "192.168.20.2"
}
