{ pkgs, pkgs-unstable, ... }:
{
  imports = [ ];
  nix = {
    enable = false; # Use determinate system
    settings = {
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    extraOptions = ''
      extra-platforms = x86_64-darwin
    '';

    # linux-builder = {
    #   enable = true;
    #   ephemeral = true;
    #   maxJobs = 8;
    #   supportedFeatures = [
    #     "kvm"
    #     "benchmark"
    #     "big-parallel"
    #   ];
    #   systems = [
    #     "aarch64-linux"
    #     "x86_64-linux"
    #   ];
    #   config = {
    #     # This can't include aarch64-linux when building on aarch64,
    #     # for reasons I don't fully understand
    #     boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
    #     virtualisation = {
    #       darwin-builder.diskSize = 60 * 1024;
    #     };
    #     nix.settings = {
    #       substituters = [
    #         "https://nix-community.cachix.org"
    #       ];
    #       trusted-public-keys = [
    #         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    #       ];
    #     };
    #   };
    # };
  };

  users.users.volodia = {
    name = "volodia";
    home = "/Users/volodia";
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    terminal-notifier
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
      package = pkgs-unstable.yabai;
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
