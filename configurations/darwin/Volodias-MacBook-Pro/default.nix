{ flake, lib, ... }:
let
  inherit (flake) inputs;
  inherit (flake.config) me;
  inherit (inputs) self;
in
{
  imports = [
    self.darwinModules.common-darwin
    self.darwinModules.nix-cache-proxy
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    users.${me.username} = {
      imports = lib.flatten (
        with self.homeModules;
        [
          common-home
          git
          zsh
          ssh
          syncthing
          mail
          packages-personal
        ]
      );
    };
    sharedModules = [
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
    ];
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Darwin-specific configuration
  system = {
    stateVersion = 5;
    primaryUser = me.username;
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  # Home Manager configuration
}
