{
  pkgs,
  user,
  lib,
  config,
  ...
}:
{
  imports = [ ];

  determinate-nix.customSettings = {
    trusted-users = [
      "root"
      "@wheel"
      "${lib.escapeShellArg user.username}"
    ];

    extra-experimental-features = [ "parallel-eval external-builders" ];
    extra-platforms = "x86_64-darwin";

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

    inherit (config.nix.settings)
      # nix-path
      download-buffer-size
      log-lines
      fallback
      lazy-trees
      eval-cores
      warn-dirty
      accept-flake-config
      post-build-hook
      extra-substituters
      extra-trusted-public-keys
      builders-use-substitutes
      max-jobs
      keep-derivations
      keep-outputs
      flake-registry
      ;
  };

  nix = {
    enable = false;
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
