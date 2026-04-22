{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.infisical
    pkgs.opentofu
  ];

  shellHook = ''
    eval $(infisical export --format=dotenv-export --silent --path=/Kubernetes/DexTek/TFController --env=default)

    export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$INFISICAL_ID
    export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$INFISICAL_SECRET
  '';
}
