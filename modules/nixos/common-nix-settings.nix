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
  inherit (flake) inputs;
  # ponytail: was lib.filterAttrs (_: lib.isType "flake") inputs — registered ALL ~25 inputs,
  # forcing flake.outPath eval for each. Whitelist only the ones actually referenced as flake:ID.
  registryInputs = {
    inherit (inputs) nixpkgs nixpkgs-unstable home-manager;
  };
  # From https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61
  # The filtering/pushing itself lives in ../../static/cachix-push.sh so that the CI
  # cache job (.github/workflows/deploy.yaml) pushes exactly the same way.
  pushScript = ../../static/cachix-push.sh;

  asyncScript = pkgs.writeShellScript "cachix-push" ''
    exec >>/var/log/nix-push-hook.log 2>&1
    echo "===== Starting cachix push at $(date) ====="

    export PATH="${
      lib.makeBinPath [
        config.nix.package
        pkgs.cachix
        pkgs.coreutils
      ]
    }:$PATH"

    export CACHIX_NAME="${me.cachixName}"
    export CACHIX_TOKEN_FILE="${config.age.secrets.cachix-token.path}"
    export IGNORE_PATTERNS="${
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
    export MAX_SIZE=$((500 * 1024 * 1024)) # 500 MB

    ${pkgs.bash}/bin/bash ${pushScript}
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
    # keep-outputs = true;
    log-lines = 50;
    fallback = true;
    # lazy-trees = true;
    # eval-cores = 0;
    warn-dirty = false;
    accept-flake-config = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
    post-build-hook = "${cachixHook}";
    # auto-optimise-store = true;
    narinfo-cache-negative-ttl = 600;
    narinfo-cache-positive-ttl = 600;
    #download-buffer-size = 1073741824; # 1 GiB
    http-connections = 50;
    connect-timeout = 10;
    # for direnv GC roots
    inherit (me) extra-substituters trusted-public-keys;
    # inherit (me) trusted-public-keys;

    # https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61

    # flake-registry = "/etc/flake-registry.json";
    flake-registry = "";

    nix-path = config.nix.nixPath;
  };
in
{
  options.services.commonNixSettings = {
    enable = lib.mkEnableOption "common Nix settings (cachix, gc, experimental features)";
  };
  imports = [
  ];
  config = lib.mkIf cfg.enable {
    # settings get written into /etc/nix/nix.custom.conf
    nixpkgs.config = {
      allowUnfree = true;
      allowInsecurePredicate = pkg: builtins.elem (lib.getName pkg) [ "tensorrt" ];
    };

    nix = {
      enable = true;
      channel.enable = false;

      extraOptions = ''
        experimental-features = nix-command flakes
        !include ${config.age.secrets.access-token.path}
      '';

      settings = common-nix-settings // {
        # experimental-features = [
        #   "nix-command"
        #   "flakes"
        # ];

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
      };

      # optimise = {
      #  automatic = true;
      # };

      #     gc = {
      #      automatic = true;
      # interval = {
      #   Weekday = 1;
      #   Hour = 0;
      #   Minute = 0;
      # };
      #     options = "--delete-older-than 8d";
      #  };

      # # pin the registry to avoid downloading and evaling a new nixpkgs version every time
      # registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
      #
      # # set the path for channels compat
      # nixPath = lib.mapAttrsToList (n: _: "${n}=${n}") flakeInputs;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) registryInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") registryInputs;
      # nixPath = [ "nixpkgs=${pkgs.path}" ];
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
