{
  pkgs,
  lib,
  config,
  flake,
  ...
}:
let
  inherit (flake.config) me;
  cfg = config.services.commonNixSettings;
  # registryMap = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
  # From https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61
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
      echo "Nothing to push to cachix"
      exit 0
    fi

    # Check if already authenticated by testing cachix config
    cat ${config.age.secrets.cachix-token.path} | ${pkgs.cachix}/bin/cachix authtoken --stdin

    ${pkgs.cachix}/bin/cachix push $CACHIX_NAME $FILTERED_PATHS
    echo "===== Finished cachix push at $(date) ====="
  '';

  cachixHook = pkgs.writeScript "cachix-push-hook" ''
    #!${pkgs.bash}/bin/bash

    # Run the entire push process asynchronously in the background using nohup
    ${pkgs.coreutils}/bin/nohup ${asyncScript}&
  '';

  # nix-path = lib.mapAttrsToList (name: flake: "${name}=flake:${flake.outPath}") registryMap;

  common-nix-settings = {
    # download-buffer-size = 1073741824; # 1 GiB
    # Keep derivations for store paths
    keep-derivations = true;
    # Add derivations to profile gc roots
    keep-env-derivations = true;
    # Keep the deps of envs
    keep-outputs = true;

    log-lines = 50;
    fallback = true;
    # lazy-trees = true;
    # eval-cores = 0;
    warn-dirty = false;
    accept-flake-config = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
    post-build-hook = "${cachixHook}";
    # for direnv GC roots
    inherit (me) trusted-public-keys;

    # https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61

    # flake-registry = "/etc/flake-registry.json";

    nix-path = config.nix.nixPath;
  };
in
{
  options.services.commonNixSettings = {
    enable = lib.mkEnableOption "common Nix settings (cachix, gc, experimental features)";
  };

  config = lib.mkIf cfg.enable {
    # settings get written into /etc/nix/nix.custom.conf
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _pkg: true;
    };

    nix = {
      enable = true;
      channel.enable = false;

      # package = lib.mkDefault pkgs.lix;
      package = lib.mkDefault pkgs.nixVersions.latest;

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
          me.username
        ];
      };

      optimise = {
        automatic = true;
      };

      gc = {
        automatic = true;
        # interval = {
        #   Weekday = 1;
        #   Hour = 0;
        #   Minute = 0;
        # };
        options = "--delete-older-than 8d";
      };

      # # pin the registry to avoid downloading and evaling a new nixpkgs version every time
      # registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
      #
      # # set the path for channels compat
      # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

    # environment.etc."flake-registry.json".text =
    #   let
    #     flakes = lib.mapAttrsToList (name: flake: {
    #       from = {
    #         id = name;
    #         type = "indirect";
    #       };
    #       to = {
    #         type = "path";
    #         path = flake.outPath;
    #       };
    #     }) registryMap;
    #   in
    #   lib.strings.toJSON {
    #     inherit flakes;
    #     version = 2;
    #   };

  };
}
