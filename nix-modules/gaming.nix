{
  config,
  lib,
  pkgs-unstable,
  ...
}:
with lib;
let
  cfg = config.services.gaming;
in
{
  options = {
    services.gaming = with types; {
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
