{
  config,
  lib,
  pkgs,
  flake,
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

  # imports = [
  #   flake.inputs.tidal-to-strawberry.homeManagerModules.default
  # ];

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = pkgs.stdenv.isLinux;

    # Enable the theme daemon for automatic switching
    services = {
      theme-daemon.enable = true;
      # tidal-to-strawberry = {
      #   enable = pkgs.stdenv.isLinux;
      #   workingDirectory = "/home/${flake.config.me.username}/Music";
      # };
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
      packages =
        (with pkgs; [
          brave
          signal-desktop
          qbittorrent
          #          zotero
          drawio
          zathura
          kitty
          kitty-themes
        ])
        ++ (lib.optionals pkgs.stdenv.isLinux [
          libnotify
          vlc
          legcord
          strawberry
          notify-desktop
          fontconfig
          distrobox
          distrobox-tui
          easyeffects
          libreoffice-qt-fresh
          freerdp
        ]);

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
