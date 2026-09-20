{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.mpv;
in
{
  options = {
    my.mpv = {
      enable = lib.mkEnableOption "MPV configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.mpv-rife
    ];
  };
}
