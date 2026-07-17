{
  config,
  lib,
  ...
}:
let
  inherit (config) me;
in
{
  config.darwin."Volodias-MacBook-Pro" = lib.mkMerge [
    config.darwin.mac
    (_: {
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      system = {
        stateVersion = 5;
        primaryUser = me.username;
      };
    })
  ];

  config.home."Volodias-MacBook-Pro" = lib.mkMerge [
    config.home.base
    config.home.desktop
  ];
}
