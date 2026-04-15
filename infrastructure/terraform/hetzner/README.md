# Hetzner

## Applying

When TLS certificates change, apply in two steps to avoid the Docker provider
connecting before the new certs are pushed to the server.

**Step 1** — regenerate and push TLS certs:

```sh
tofu apply \
  -target=tls_private_key.docker_ca \
  -target=tls_private_key.docker_server \
  -target=tls_private_key.docker_client \
  -target=tls_self_signed_cert.docker_ca \
  -target=tls_cert_request.docker_server \
  -target=tls_cert_request.docker_client \
  -target=tls_locally_signed_cert.docker_server \
  -target=tls_locally_signed_cert.docker_client \
  -target=ssh_resource.docker_tls_setup
```

**Step 2** — apply everything else:

```sh
tofu apply
```
