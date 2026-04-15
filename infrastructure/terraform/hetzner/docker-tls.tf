resource "tls_private_key" "docker_ca" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "docker_ca" {
  private_key_pem = tls_private_key.docker_ca.private_key_pem

  subject {
    common_name = "Docker CA"
  }

  validity_period_hours = 87600
  is_ca_certificate     = true

  allowed_uses = ["cert_signing", "crl_signing"]
}

resource "tls_private_key" "docker_server" {
  algorithm = "ED25519"
}

resource "tls_cert_request" "docker_server" {
  private_key_pem = tls_private_key.docker_server.private_key_pem

  subject {
    common_name = "Docker Server"
  }

  ip_addresses = [hcloud_server.pangolin.ipv4_address]
}

resource "tls_locally_signed_cert" "docker_server" {
  cert_request_pem   = tls_cert_request.docker_server.cert_request_pem
  ca_private_key_pem = tls_private_key.docker_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.docker_ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = ["server_auth"]
}

resource "tls_private_key" "docker_client" {
  algorithm = "ED25519"
}

resource "tls_cert_request" "docker_client" {
  private_key_pem = tls_private_key.docker_client.private_key_pem

  subject {
    common_name = "Docker Client"
  }
}

resource "tls_locally_signed_cert" "docker_client" {
  cert_request_pem   = tls_cert_request.docker_client.cert_request_pem
  ca_private_key_pem = tls_private_key.docker_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.docker_ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = ["client_auth"]
}

resource "ssh_resource" "docker_tls_setup" {
  depends_on = [ssh_resource.docker_install]

  triggers = {
    ca_cert     = tls_self_signed_cert.docker_ca.cert_pem
    server_cert = tls_locally_signed_cert.docker_server.cert_pem
    server_key  = tls_private_key.docker_server.private_key_pem
  }

  host        = hcloud_server.pangolin.ipv4_address
  user        = var.ssh_user
  private_key = local.ssh_key

  pre_commands = [
    "mkdir -p /etc/docker/certs",
    "mkdir -p /etc/systemd/system/docker.service.d",
  ]

  file {
    content     = tls_self_signed_cert.docker_ca.cert_pem
    destination = "/etc/docker/certs/ca.pem"
    permissions = "0644"
  }

  file {
    content     = tls_locally_signed_cert.docker_server.cert_pem
    destination = "/etc/docker/certs/server-cert.pem"
    permissions = "0644"
  }

  file {
    content     = tls_private_key.docker_server.private_key_pem
    destination = "/etc/docker/certs/server-key.pem"
    permissions = "0600"
  }

  file {
    content = jsonencode({
      hosts      = ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"]
      tls        = true
      tlsverify  = true
      tlscacert  = "/etc/docker/certs/ca.pem"
      tlscert    = "/etc/docker/certs/server-cert.pem"
      tlskey     = "/etc/docker/certs/server-key.pem"
    })
    destination = "/etc/docker/daemon.json"
    permissions = "0644"
  }

  file {
    content     = "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock\n"
    destination = "/etc/systemd/system/docker.service.d/override.conf"
    permissions = "0644"
  }

  commands = [
    "systemctl daemon-reload",
    "systemctl restart docker",
  ]
}
