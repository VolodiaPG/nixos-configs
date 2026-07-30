# ponytail: determinate DROPPED — its darwin module pulls Determinate's custom nix fork
# (flakehub → flake-compat → defeats the npins speed goal). Use nixpkgs nix instead.
{
  lib,
  ...
}:

{
  imports = [ ../nixos/common-nix-settings.nix ];

  nix.enable = lib.mkForce true;

  # ponytail: the old flake used determinate with nix.enable=false, which kept nix-darwin's
  # nixpkgs-flake.nix auto registry/nixPath inert (they're gated on nix.enable). Now that we
  # use nixpkgs nix, disable those auto-setters explicitly — the imported nixos
  # common-nix-settings.nix already sets nix.registry/nixPath, and nix-darwin's would
  # conflict (both at mkDefault) on nix.registry.nixpkgs.to.path.
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;
}
