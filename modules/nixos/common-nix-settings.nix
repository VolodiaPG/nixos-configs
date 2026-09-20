# Nix daemon configuration shared by the NixOS hosts and (via
# modules/darwin/common-nix-settings.nix) the darwin host.
#
# These settings are written to /etc/nix/nix.custom.conf; Determinate Nix owns
# /etc/nix/nix.conf itself and includes that file.
{
  pkgs,
  lib,
  config,
  flake,
  ...
}:
let
  inherit (flake) inputs;
  inherit (flake.config) me;
  cfg = config.my.nixSettings;

  # Inputs registered as `flake:<name>` in the registry and on NIX_PATH.
  # Whitelisted rather than derived from `inputs`: registering all ~25 inputs
  # forces flake.outPath evaluation for every one of them on each rebuild.
  registryInputs = {
    inherit (inputs) nixpkgs nixpkgs-unstable home-manager;
  };

  # post-build-hook: push freshly built paths to cachix, out of band so builds
  # are not blocked on the upload.
  #
  # The filtering and pushing live in static/cachix-push.sh so the CI cache job
  # (.github/workflows/deploy.yaml) pushes exactly the same way — IGNORE_PATTERNS
  # and MAX_SIZE below must stay in sync with that workflow.
  # Adapted from https://github.com/ojsef39/nix-base/blob/2e89e31/nix/core.nix#L61
  pushScript = ../../static/cachix-push.sh;

  asyncScript = pkgs.writeShellScript "cachix-push" ''
    exec >>/var/log/nix-push-hook.log 2>&1
    echo "===== Starting cachix push at $(date) ====="

    export PATH="${
      lib.makeBinPath [
        pkgs.nix
        pkgs.cachix
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
      ]
    }:$PATH"

    export CACHIX_NAME="${me.cachixName}"
    export CACHIX_TOKEN_FILE="${config.age.secrets.cachix-token.path}"
    export IGNORE_PATTERNS="${
      lib.concatStringsSep " " [
        "source"
        "etc"
        "system"
        "home-manager"
        "user-environment"
        me.username
      ]
    }"
    export MAX_SIZE=$((500 * 1024 * 1024)) # 500 MB

    ${pkgs.bash}/bin/bash ${pushScript}
    echo "===== Finished cachix push at $(date) ====="
  '';

  cachixHook = pkgs.writeScript "cachix-push-hook" ''
    #!${pkgs.bash}/bin/bash

    # Run the entire push process asynchronously in the background using nohup
    ${pkgs.coreutils}/bin/nohup ${asyncScript}&
  '';
in
{
  options.my.nixSettings.enable = lib.mkEnableOption "shared Nix daemon settings (substituters, cachix push hook, flake registry)";

  config = lib.mkIf cfg.enable {
    nixpkgs.config = import (flake.self + "/lib/nixpkgs-config.nix") { inherit lib; };

    nix = {
      enable = true;
      channel.enable = false;

      # Not expressible in `settings`: `!include` has no structured equivalent.
      extraOptions = ''
        experimental-features = nix-command flakes
        !include ${config.age.secrets.access-token.path}
      '';

      settings = {
        # Keep derivations and their build-time deps as GC roots, so that
        # `nix develop` / direnv shells survive a garbage collect.
        keep-derivations = true;
        keep-env-derivations = true;

        log-lines = 50;
        fallback = true;
        warn-dirty = false;
        accept-flake-config = true;
        builders-use-substitutes = true;
        max-jobs = "auto";
        http-connections = 50;
        connect-timeout = 10;
        narinfo-cache-negative-ttl = 600;
        narinfo-cache-positive-ttl = 600;

        post-build-hook = "${cachixHook}";

        # Single source of truth for the caches: config.nix. Note that
        # flake.nix's `nixConfig` has to repeat them (Nix rejects thunks there).
        inherit (me) extra-substituters trusted-public-keys;

        allowed-users = [
          "root"
          "wheel"
          "@wheel"
          me.username
        ];
        trusted-users = [
          "root"
          "wheel"
          "@wheel"
          me.username
        ];

        # Empty: resolve `flake:<id>` through the pinned `registry` below rather
        # than fetching (and re-evaluating) the global registry over the network.
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };

      registry = lib.mapAttrs (_: flake: { inherit flake; }) registryInputs;
      nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") registryInputs;
    };
  };
}
