{
  pkgs,
  user,
  lib,
  inputs,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in

{
  imports = [ ];
  determinate-nix = {
    customSettings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-experimental-features = [
        "parallel-eval"
        "external-builders"
      ];
      external-builders = builtins.toJSON [
        {
          systems = [
            "aarch64-linux"
            "x86_64-linux"
          ];
          program = "/usr/local/bin/determinate-nixd";
          args = [ "builder" ];
        }
      ];
      keep-outputs = true;
      keep-derivations = true;
      sandbox = "relaxed";
      extra-platforms = "x86_64-darwin";
      log-lines = 50;
      fallback = true;

      extra-trusted-users = [
        "${user.username}"
        "@admin"
        "@root"
        "@sudo"
        "@wheel"
        "@staff"
      ];

      # Disable global registry
      flake-registry = "";
      lazy-trees = true;
      eval-cores = 0; # Enable parallel evaluation across all cores
      warn-dirty = false;
    };
  };

  nix = {
    enable = false; # Use determinate system
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
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

  # launchd.daemons.linux-builder.serviceConfig = {
  #   StandardOutPath = "/var/log/linux-builder.log";
  #   StandardErrorPath = "/var/log/linux-builder.log";
  # };

  system.activationScripts.extraActivation.text = ''
    /usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license
  '';

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
}
