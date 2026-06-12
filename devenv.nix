{ pkgs, ... }:
{
  packages = [
    pkgs.infisical
    pkgs.opentofu
    pkgs.tofu-ls
  ];

  enterShell = ''
    if ! infisical login status >/dev/null 2>&1; then
      echo ""
      echo "Infisical session expired."
      echo "Run: infisical login && direnv reload"
      echo ""
    else
      eval $(infisical export --format=dotenv-export --silent --path=/Kubernetes/DexTek/TFController --env=default)
      export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$INFISICAL_ID
      echo INFISICAL_UNIVERSAL_AUTH_CLIENT_ID exported
      export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$INFISICAL_SECRET
      echo INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET exported
    fi
  '';
}
