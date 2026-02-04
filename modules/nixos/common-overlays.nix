{ flake, ... }:
let
  inherit (flake) self;
in
{
  nixpkgs.overlays = [
    self.overlays.default
  ];
}
