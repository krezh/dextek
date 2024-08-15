data "sops_file" "secrets" {
  source_file = "sopsSecrets/secrets.sops.yaml"
}
