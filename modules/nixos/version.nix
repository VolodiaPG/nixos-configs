{
  flake,
  ...
}:

let
  inherit (flake) inputs;
  nixpkgsRev = inputs.nixpkgs.sourceInfo.rev;
in
{
  system.nixos.versionSuffix = ".${builtins.substring 0 7 nixpkgsRev}";
  system.nixos.revision = nixpkgsRev;
}
