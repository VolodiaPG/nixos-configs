# Home Manager wiring for nix-darwin hosts.
#
# Same contract as modules/nixos/home-manager.nix: hosts import this and only
# declare what to enable for the user.
{
  flake,
  pkgs-unstable,
  lib,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) me;
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit flake pkgs-unstable;
    };

    sharedModules = [
      self.homeModules.default
      (self + "/secrets/home-manager.nix")
      inputs.agenix.homeManagerModules.default
    ];

    users.${me.username}.home.stateVersion = lib.mkDefault "22.05";
  };
}
