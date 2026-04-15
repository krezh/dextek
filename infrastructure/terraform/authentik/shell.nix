{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.infisical
    pkgs.opentofu
  ];

  shellHook = ''
    export TF_VAR_infisical_client_id=$(infisical secrets get INFISICAL_CLIENT_ID \
      --env default \
      --path=/Kubernetes/DexTek/TFController \
      --plain)

    export TF_VAR_infisical_client_secret=$(infisical secrets get INFISICAL_CLIENT_SECRET \
      --env=default \
      --path=/Kubernetes/DexTek/TFController \
      --plain)
  '';
}
