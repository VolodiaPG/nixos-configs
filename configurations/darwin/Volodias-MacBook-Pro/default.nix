# Volodias-MacBook-Pro — nix-darwin host.
{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [
    self.darwinModules.default
    self.darwinModules.home-manager
    inputs.agenix.darwinModules.age
    (self + "/secrets/nixos.nix")
  ];

  # Options defined by this repo (modules/darwin/*.nix).
  my = {
    darwin.enable = true;
    nixSettings.enable = true;
  };

  home-manager.users.${me.username} = {
    my = {
      commonHome.enable = true;
      interactive.enable = true;
      chezmoi.enable = true;
      gui.enable = true;
      neovim.enable = true;
      themeDaemon.enable = true;
      mpv.enable = true;
    };

    # Upstream Home Manager options
    services.syncthing.enable = true;
  };

  system = {
    stateVersion = 5;
    primaryUser = me.username;
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };
}
