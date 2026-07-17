{
  config,
  inputs,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      imports = [
        inputs.tidal-to-strawberry.homeManagerModules.default
      ];

      fonts.fontconfig.enable = pkgs.stdenv.isLinux;

      services = {
        tidal-to-strawberry = {
          enable = pkgs.stdenv.isLinux;
          workingDirectory = "/home/${me.username}/Music";
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
        packages =
          with pkgs;
          [
            signal-desktop
            qbittorrent
            drawio
            kitty
            kitty-themes
          ]
          ++ (lib.optionals pkgs.stdenv.isLinux [
            filezilla
            brave
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
