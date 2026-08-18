{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mpv;
in
{
  options = {
    mpv = {
      enable = lib.mkEnableOption "MPV configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.mpv-rife
    ];
  };
}
