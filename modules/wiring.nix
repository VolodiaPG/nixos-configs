{
  lib,
  inputs,
  self,
  ...
}:
{
  flake.overlays.default = import ../overlays/default.nix {
    flake = {
      inherit inputs self;
    };
  };

  perSystem = { pkgs, ... }: {
    packages = lib.pipe ../packages [
      builtins.readDir
      (lib.filterAttrs (_: v: v == "directory"))
      (lib.mapAttrsToList (
        name: _: lib.nameValuePair name (pkgs.callPackage ../packages/${name}/default.nix { })
      ))
      builtins.listToAttrs
    ];
  };
}
