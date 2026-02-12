{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.gui;
in
{
  options = {
    gui = with types; {
      enable = mkEnableOption "GUI configuration for users";
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    # Enable the theme daemon for automatic switching
    services.theme-daemon.enable = true;

    programs = {
      kitty.enable = true;
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
      direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };
    };

    home = {
      packages = with pkgs; [
        fontconfig
        libnotify
        notify-desktop
      ];

      file = {
        ".config/discord/settings.json".text = ''
          {
            "BACKGROUND_COLOR": "#202225",
            "IS_MAXIMIZED": false,
            "IS_MINIMIZED": true,
            "SKIP_HOST_UPDATE": true,
            "WINDOW_BOUNDS": {
              "x": 307,
              "y": 127,
              "width": 1280,
              "height": 725
            }
          }
        '';
      };

      stateVersion = "22.05";
    };
  };
}
