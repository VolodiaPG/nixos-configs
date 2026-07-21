{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.gui;
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    gui = {
      enable = mkEnableOption "GUI configuration for users";
    };
  };

  imports = [
    flake.inputs.tidal-to-strawberry.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = pkgs.stdenv.isLinux;

    # Enable the theme daemon for automatic switching
    services = {
      theme-daemon.enable = true;
      tidal-to-strawberry = {
        enable = pkgs.stdenv.isLinux;
        workingDirectory = "/home/${flake.config.me.username}/Music";
      };
    };
    programs = {
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
      packages = [
        pkgs.signal-desktop
        pkgs.qbittorrent
        pkgs.drawio
        pkgs.kitty
        pkgs.kitty-themes
      ]
      ++ (lib.optionals pkgs.stdenv.isLinux [
        pkgs.filezilla
        pkgs.brave
        pkgs.libnotify
        pkgs.vlc
        pkgs.legcord
        pkgs.strawberry
        pkgs.notify-desktop
        pkgs.fontconfig
        pkgs.distrobox
        pkgs.distrobox-tui
        pkgs.easyeffects
        pkgs.libreoffice-qt-fresh
        pkgs.freerdp
        pkgs.orca-slicer
      ]);

      pointerCursor = {
        package = pkgs.graphite-cursors;
        name = "graphite-dark";
      };

      file = {
        ".config/kitty/kitty-themes".source = "${pkgs.kitty-themes}/share/kitty-themes";
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
