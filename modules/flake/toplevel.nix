# This file is the entrypoint for flake-parts in the nixos-unified template
{ inputs, ... }:
{
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
  ];
}
