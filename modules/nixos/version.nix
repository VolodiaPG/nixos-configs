{
  flake,
  ...
}:

let
  inherit (flake) sources;
  nixpkgsPin = sources.nixpkgs;
in
{
  # npins exposes .revision
  system.nixos.versionSuffix = ".${builtins.substring 0 7 nixpkgsPin.revision}";
  system.nixos.revision = nixpkgsPin.revision;
}
