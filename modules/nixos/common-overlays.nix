{
  flake,
  config,
  lib,
  ...
}:
let
  inherit (flake) self;
  cfg = config.services.commonOverlays;
in
{
  options.services.commonOverlays = {
    enable = lib.mkEnableOption "common overlays from this flake";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      self.overlays.default
    ];
  };
}
