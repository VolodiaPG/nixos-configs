{ flake, ... }:
let
  inherit (flake) inputs;
in
{
  imports = [
    inputs.determinate.nixosModules.default
  ];
}
