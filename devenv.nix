{ pkgs, ... }:
{
  packages = [
    pkgs.infisical
    pkgs.opentofu
    pkgs.tofu-ls
    pkgs.pulumi
    pkgs.pulumiPackages.pulumi-go
  ];

  enterShell = ''
    export GITHUB_TOKEN=$(gh auth token)
    INFISICAL_OUTPUT=$(timeout 5 infisical export --format=dotenv-export --silent --path=/Kubernetes/DexTek/TFController --env=default 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$INFISICAL_OUTPUT" ]; then
      eval "$INFISICAL_OUTPUT"
      export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$INFISICAL_ID
      echo INFISICAL_UNIVERSAL_AUTH_CLIENT_ID exported
      export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$INFISICAL_SECRET
      echo INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET exported
    else
      echo ""
      echo "Infisical session expired."
      echo "Run: infisical login && direnv reload"
      echo ""
    fi
  '';
}
