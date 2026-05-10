{ pkgs, ... }: {
  packages = [
    pkgs.infisical
    pkgs.opentofu
  ];

  enterShell = ''
    eval $(infisical export --format=dotenv-export --silent --path=/Kubernetes/DexTek/TFController --env=default)

    export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$INFISICAL_ID
    echo INFISICAL_UNIVERSAL_AUTH_CLIENT_ID exported
    export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$INFISICAL_SECRET
    echo INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET exported
  '';
}
