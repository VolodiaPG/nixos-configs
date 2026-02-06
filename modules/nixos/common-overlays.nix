{
  flake,
  ...
}:
let
  inherit (flake.inputs) self;
in
{
  nixpkgs.overlays = [
    self.overlays.default
  ];
}
