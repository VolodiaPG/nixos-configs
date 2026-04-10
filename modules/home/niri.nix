{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.wm.niri;
in
{
  options = {
    wm.niri = with types; {
      enable = mkEnableOption "niri Wayland compositor configuration";

      package = mkOption {
        type = package;
        default = pkgs.niri;
        description = "The niri package to use";
      };
    };
  };

  config = mkIf cfg.enable {
    nirius.enable = true;
    home.packages = with pkgs; [
      cfg.package

      # Core niri utilities
      fuzzel # Application launcher

      # Screenshot tools
      grim
      slurp
      satty # Screenshot annotation

      # Clipboard
      wl-clipboard
      cliphist

      # Background and theming
      swaybg
      wpaperd

      # Additional Wayland utilities
      wlogout # Logout menu
      wlr-randr # Display configuration

      # Polkit agent
      polkit_gnome

      # KDE Connect
      kdePackages.qttools

      wl-mirror
    ];
    xdg = {
      portal = {
        enable = true;
        config = {
          common = {
            default = [
              "gtk"
              "gnome"
            ];
          };
          niri = {
            default = [
              "gtk"
              "gnome"
            ];
          };
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        xdgOpenUsePortal = true;
      };

      # e.g. for slack, etc
      configFile."electron-flags.conf".text = ''
        --enable-features=UseOzonePlatform
        --ozone-platform=wayland
      '';
    };
    gtk.enable = true;

    # Fuzzel launcher configuration
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Noto Sans:size=11";
          prompt = "❯ ";
          width = 50;
          lines = 15;
          horizontal-pad = 20;
          vertical-pad = 10;
          inner-pad = 8;
          line-height = 24;
        };

        colors = {
          background = "1e1e2eff";
          text = "cdd6f4ff";
          match = "f38ba8ff";
          selection = "585b70ff";
          selection-text = "cdd6f4ff";
          selection-match = "f38ba8ff";
          border = "f38ba8ff";
        };

        border = {
          width = 2;
          radius = 12;
        };
      };
    };

    services.kdeconnect.enable = true;

    programs.noctalia-shell = {
      enable = true;
    };
  };
}
