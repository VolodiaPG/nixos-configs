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

  nix = {
    enable = false; # Use determinate system
    settings = {
      sandbox = "relaxed";
      extra-platforms = "x86_64-darwin";
      keep-outputs = true;
      keep-derivations = true;
      warn-dirty = false;
      build-users-group = "nixbld";
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      log-lines = 50;
      fallback = true;
      experimental-features = "nix-command flakes";
      extra-experimental-features = "parallel-eval";
      eval-cores = 0;
      lazy-trees = true;
      flake-registry = "";
    };
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
