{
  pkgs,
  user,
  lib,
  inputs,
  config,
  ...
}:
let
  # From https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61
  cachixHook = pkgs.writeScript "cachix-push-hook" ''
    #!/bin/bash
    CACHIX_NAME="${user.cachixName}"
    IGNORE_PATTERNS="${
      lib.concatStringsSep " " (
        [
          "source"
          "etc"
          "system"
          "home-manager"
          "user-environment"
        ]
        ++ [ user.username ]
      )
    }"

    # Filter out ignored patterns
    FILTERED_PATHS=""
    for path in $OUT_PATHS; do
      # Check if path should be ignored
      should_ignore=false
      if [[ -n "$IGNORE_PATTERNS" ]]; then
        IFS=' ' read -ra PATTERN_ARRAY <<< "$IGNORE_PATTERNS"
        for pattern in "''${PATTERN_ARRAY[@]}"; do
          if [[ -n "$pattern" && "$path" == *"$pattern"* ]]; then
            should_ignore=true
            break
          fi
        done
      fi

      if [[ "$should_ignore" == "false" ]]; then
        FILTERED_PATHS="$FILTERED_PATHS $path"
      fi
    done

    if [ -z "$FILTERED_PATHS" ]; then
      echo "Nothing to push"
      exit 0
    fi

    echo "Authenticating with cachix..."
    cat ${config.age.secrets.cachix-token.path} | ${pkgs.cachix}/bin/cachix authtoken --stdin

    ${pkgs.cachix}/bin/cachix push $CACHIX_NAME $FILTERED_PATHS
  '';

  common-nix-settings = {
    download-buffer-size = "1073741824"; # 1 GiB
    nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];

    log-lines = 50;
    fallback = true;
    flake-registry = "";
    lazy-trees = true;
    eval-cores = 0;
    warn-dirty = false;
    accept-flake-config = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
    post-build-hook = "${cachixHook}";

    # https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61

    extra-substituters = [
      "https://volodiapg.cachix.org"
      "https://install.determinate.systems"
      "https://nixos-apple-silicon.cachix.org"
      "https://numtide.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "volodiapg.cachix.org-1:XcJQeUW+7kWbHEqwzFbwIJ/fLix3mddEYa/kw8XXoRI="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];

  };
in
{
  # settings get written into /etc/nix/nix.custom.conf
  nix = {
    channel.enable = false;
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    settings = common-nix-settings;
  };
}
