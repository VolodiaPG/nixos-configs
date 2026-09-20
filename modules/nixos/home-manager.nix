# Home Manager wiring shared by every NixOS host that has a user.
#
# Hosts import this (via `self.nixosModules.home-manager`) and then only declare
# *what* to enable for the user, in configurations/nixos/<host>/home.nix.
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
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    # Build the user's packages from the system pkgs (one nixpkgs instance, and
    # the repo overlay applies to home configs too).
    useGlobalPkgs = true;
    useUserPackages = true;

    # Same arguments the NixOS modules get, so home modules can use `flake`
    # (config.me, inputs, self) and `pkgs-unstable` the same way.
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
