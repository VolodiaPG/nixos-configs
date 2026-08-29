# ponytail: Determinate nix via nix-src overlay (applied in flake.nix mkDarwin + common-overlays.nix).
# Overlay-only swap — no determinate darwin module, so nix.enable stays true and nix-darwin
# keeps managing the daemon. The Determinate installer's /etc/nix/nix.conf coexists with
# nix-darwin's nix.settings via nix.custom.conf include.
{
  lib,
  flake,
  ...
}:
let
  inherit (flake) inputs;
in
{
  imports = [
    ../nixos/common-nix-settings.nix
    inputs.determinate.darwinModules.default
  ];
  # For nix determinate
  nix.enable = lib.mkForce false;

  determinateNix.enable = true;

  # ponytail: the old flake used determinate with nix.enable=false, which kept nix-darwin's
  # nixpkgs-flake.nix auto registry/nixPath inert (they're gated on nix.enable). Now that we
  # use nixpkgs nix, disable those auto-setters explicitly — the imported nixos
  # common-nix-settings.nix already sets nix.registry/nixPath, and nix-darwin's would
  # conflict (both at mkDefault) on nix.registry.nixpkgs.to.path.
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;
}
