# Applies the repo overlay (overlays/default.nix). The overlay itself is built
# in flake.nix — per (system, cuda) pair — and handed to every module as the
# `overlay` specialArg.
{ overlay, ... }:
{
  nixpkgs.overlays = [ overlay ];
}
