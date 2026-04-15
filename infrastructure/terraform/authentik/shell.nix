{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.infisical
    pkgs.opentofu
  ];

  shellHook = ''
    export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$(infisical secrets get INFISICAL_ID \
      --env default \
      --path=/Kubernetes/DexTek/TFController \
      --plain)

    export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$(infisical secrets get INFISICAL_SECRET \
      --env=default \
      --path=/Kubernetes/DexTek/TFController \
      --plain)
  '';
}
