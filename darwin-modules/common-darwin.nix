{
  pkgs,
  user,
  lib,
  inputs,
  config,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
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
in

{
  imports = [ ];
  determinate-nix.customSettings = {
    # settings get written into /etc/nix/nix.custom.conf
    "download-buffer-size" = "1073741824"; # 1 GiB
    nix-path = lib.mapAttrsToList (name: flake: "${name}=${flake.outPath}") flakeInputs;
    trusted-users = [
      "root"
      "@wheel"
      "${lib.escapeShellArg user.username}"
    ];
    extra-experimental-features = [ "parallel-eval external-builders" ];
    extra-platforms = "x86_64-darwin";
    log-lines = 50;
    fallback = true;

    flake-registry = "";
    lazy-trees = true;
    eval-cores = 0;
    warn-dirty = false;

    accept-flake-config = true;
    post-build-hook = "${cachixHook}";
    # Enable Determinate Nix's native Linux builder (requires access approval)
    external-builders = builtins.toJSON [
      {
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];
        program = "/usr/local/bin/determinate-nixd";
        args = [
          "builder"
          "--memory-size"
          "12884901888"
          "--cpu-count"
          "8"
        ];
      }
    ];

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

  nix = {
    enable = false; # Use determinate system
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=${n}") flakeInputs;
    settings = {
      accept-flake-config = true;
    };
  };

  users.users."${user.username}" = {
    name = user.username;
    home = user.homeDirectory;
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    terminal-notifier

    yabai
    skhd
  ];

  services = {
    yabai = {
      enable = true;
      package = pkgs.yabai;
      enableScriptingAddition = true;
    };
    skhd = {
      enable = false;
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  environment.shellInit = ''
    ulimit -n 524288
  '';

  launchd = {
    daemons = {
      # fixes "Too many open files" errors
      limit-maxfiles = {
        script = ''
          /bin/launchctl limit maxfiles 524288 524288
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = false;
          Label = "org.nixos.limit-maxfiles";
          StandardOutPath = "/var/log/limit-maxfiles.log";
          StandardErrorPath = "/var/log/limit-maxfiles.log";
        };
      };
    };
  };

  system = {
    defaults = {
      # Specifies the duration of a smooth frame-size change
      NSGlobalDomain.NSWindowResizeTime = 0.001;
    };

    activationScripts.extraActivation.text = ''
      /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
    '';
    stateVersion = 5;
  };
}
