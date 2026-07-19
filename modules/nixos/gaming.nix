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
      (steam.override {
        extraPkgs = _: [
          mono
          gtk3
          gtk3-x11
          libgdiplus
          zlib
        ];
      }).run
      popcorntime
      qbittorrent
      # obs-studio
      # obs-studio-plugins.wlrobs
      # obs-studio-plugins.obs-pipewire-audio-capture
      # zoom-us
    ];

    programs.steam.enable = true;
  };
}
