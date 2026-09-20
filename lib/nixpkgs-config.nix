# The `nixpkgs.config` used by *every* pkgs instance in this repo.
#
# Imported from two places, which must agree or you get two nixpkgs instances
# (and therefore two builds of everything):
#   - flake.nix, for the pkgs instances the flake builds by hand
#     (`pkgsUnstable`, the darwin `pkgs`, the `packages` output);
#   - modules/nixos/common-nix-settings.nix, for the pkgs instance NixOS and
#     nix-darwin build from `nixpkgs.config`.
{ lib }:
{
  allowUnfree = true;

  # tensorrt is marked insecure upstream but has no maintained alternative for
  # the CUDA video pipeline (see packages/mpv-rife).
  allowInsecurePredicate = pkg: lib.getName pkg == "tensorrt";
}
