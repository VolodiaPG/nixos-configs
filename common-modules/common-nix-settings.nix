{
  pkgs,
  user,
  lib,
  config,
  inputs,
  ...
}:
let
  registryMap = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
  # From https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61
  cachixHook = pkgs.writeScript "cachix-push-hook" ''
    #!${pkgs.bash}/bin/bash

    # Run the entire push process asynchronously in the background using nohup
    ${pkgs.coreutils}/bin/nohup ${pkgs.bash}/bin/bash -c '
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
        echo "Nothing to push to cachix"
        exit 0
      fi

      # Check if already authenticated by testing cachix config
      cat ${config.age.secrets.cachix-token.path} | ${pkgs.cachix}/bin/cachix authtoken --stdin

      ${pkgs.cachix}/bin/cachix push $CACHIX_NAME $FILTERED_PATHS
    ' >/dev/null 2>&1 &

    # Immediately return to avoid blocking the build
    exit 0
  '';

  common-nix-settings = {
    download-buffer-size = "1073741824"; # 1 GiB
    # nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];

    log-lines = 50;
    fallback = true;
    lazy-trees = true;
    eval-cores = 0;
    warn-dirty = false;
    accept-flake-config = true;
    builders-use-substitutes = true;
    max-jobs = "auto";
    post-build-hook = "${cachixHook}";
    # for direnv GC roots
    keep-derivations = true;
    keep-outputs = true;
    inherit (user) trusted-public-keys;

    # https://github.com/ojsef39/nix-base/blob/2e89e31ef7148608090db3e19700dc79365991f3/nix/core.nix#L61

    flake-registry = "/etc/flake-registry.json";
    nix-path = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") registryMap;
  };
in
{
  # settings get written into /etc/nix/nix.custom.conf
  nix = {
    channel.enable = false;
    settings = common-nix-settings;

    # # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    # registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
    #
    # # set the path for channels compat
    # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  environment.etc."flake-registry.json".text =
    let
      flakes = lib.mapAttrsToList (name: flake: {
        from = {
          id = name;
          type = "indirect";
        };
        to = {
          type = "path";
          path = flake.outPath;
        };
      }) registryMap;
    in
    lib.strings.toJSON {
      inherit flakes;
      version = 2;
    };

}
