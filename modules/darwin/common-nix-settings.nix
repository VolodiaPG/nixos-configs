{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

{
  imports = [
    ../nixos/common-nix-settings.nix
    flake.inputs.determinate.darwinModules.default
  ];

  nix.enable = lib.mkForce false;
  determinateNix = {
    enable = true;
    customSettings.trusted-users = [
      "root"
      flake.config.me.username
      "@admin"
    ];
  };
}
