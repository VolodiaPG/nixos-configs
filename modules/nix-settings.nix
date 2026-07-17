{
  config,
  inputs,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;

      asyncScript = pkgs.writeScript "cachix-push-hook" ''
        exec >>/var/log/nix-push-hook.log 2>&1
        echo "===== Starting cachix push at $(date) ====="
        CACHIX_NAME="${me.cachixName}"
        IGNORE_PATTERNS="${
          lib.concatStringsSep " " (
            [
              "source"
              "etc"
              "system"
              "home-manager"
              "user-environment"
            ]
            ++ [ me.username ]
          )
        }"

        FILTERED_PATHS=""
        for path in $OUT_PATHS; do
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
          echo "Nothing to push to cachix"
          exit 0
        fi

        cat ${config.age.secrets.cachix-token.path} | ${pkgs.cachix}/bin/cachix authtoken --stdin

        ${pkgs.cachix}/bin/cachix push $CACHIX_NAME $FILTERED_PATHS
        echo "===== Finished cachix push at $(date) ====="
      '';

      cachixHook = pkgs.writeScript "cachix-push-hook" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.coreutils}/bin/nohup ${asyncScript}&
      '';

      common-nix-settings = {
        keep-derivations = true;
        keep-env-derivations = true;
        keep-outputs = true;

        log-lines = 50;
        fallback = true;
        warn-dirty = false;
        accept-flake-config = false;
        builders-use-substitutes = true;
        max-jobs = "auto";
        post-build-hook = "${cachixHook}";
        narinfo-cache-negative-ttl = 600;
        narinfo-cache-positive-ttl = 600;
        inherit (me) trusted-public-keys;

        flake-registry = "";

        nix-path = config.nix.nixPath;
      };
    in
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnsupportedSystem = false;
      };

      nix = {
        enable = true;
        channel.enable = false;

        extraOptions = ''
          experimental-features = nix-command flakes
          !include ${config.age.secrets.access-token.path}
        '';

        settings = common-nix-settings // {
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          allowed-users = [
            "root"
            "wheel"
            "@wheel"
            me.username
          ];
          trusted-users = [
            "root"
            "@admin"
            me.username
          ];
        };

        registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };
    };

  config.darwin.mac =
    {
      lib,
      ...
    }:
    {
      imports = [ inputs.determinate.darwinModules.default ];
      nix.enable = lib.mkForce false;
      determinateNix = {
        enable = true;
        customSettings.trusted-users = [
          "root"
          me.username
          "@admin"
        ];
      };
    };
}
