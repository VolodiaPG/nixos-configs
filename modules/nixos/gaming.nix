{
  config,
  lib,
  pkgs-unstable,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.gaming;
in
{
  options = {
    services.gaming = {
      enable = mkEnableOption "gaming";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs-unstable; [
      faugus-launcher
      gamemode
      # obs-studio
      # obs-studio-plugins.wlrobs
      # obs-studio-plugins.obs-pipewire-audio-capture
      # zoom-us
    ];

    programs.steam = {
      enable = true;
      package = pkgs-unstable.steam;
    };
  };
}
