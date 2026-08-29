{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.wm.hyprland;
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options = {
    wm.hyprland = {
      enable = mkEnableOption "hyprland Wayland compositor configuration";

      package = mkOption {
        type = lib.types.package;
        default = pkgs.hyprland;
        description = "The hyprland package to use";
      };
    };
  };

  config = mkIf cfg.enable {
    # wayland.windowManager.hyprland = {
    #   enable = true;
    #   inherit (cfg) package;
    # };

    home.packages = [
      cfg.package

      # Core hyprland utilities
      # pkgs.fuzzel # Application launcher

      # Screenshot tools
      pkgs.grim
      pkgs.slurp
      pkgs.satty # Screenshot annotation

      # Clipboard
      pkgs.wl-clipboard
      pkgs.cliphist

      # Background and theming
      pkgs.swaybg
      pkgs.wpaperd

      # Additional Wayland utilities
      pkgs.wlogout # Logout menu

      # Polkit agent
      pkgs.polkit_gnome

      # KDE Connect
      pkgs.kdePackages.qttools

      # Keyboard brightness
      pkgs.brightnessctl

      pkgs.xdg-terminal-exec
    ];

    xdg = {
      portal = {
        enable = true;
        xdgOpenUsePortal = true;
        # configPackages = [ pkgs.gnome-session ];
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.hyprland = {
          default = "hyprland;gtk;";
          "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
          "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };

    # e.g. for slack, etc
    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer
      --ozone-platform=wayland
    '';

    # xdg-desktop-portal-hyprland screencopy config.
    # force_shm works around NVIDIA / multi-GPU DMA-BUF allocation failures
    # that break whole-monitor capture while window capture still works.
    # cursor_mode = 2 embeds the cursor (needed for browser-based shares).
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        force_shm = true
        max_fps = 60
        cursor_mode = 2
      }
    '';

    # Fuzzel launcher configuration
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          placeholder = "Type to search...";
          prompt = "'❯ '";
          launch-prefix = "uwsm app --";
          match-counter = true;
          terminal = "xdg-terminal-exec";
          horizontal-pad = 40;
          lines = 15;
          line-height = 24;
          vertical-pad = 10;
          inner-pad = 8;
          image-size-ratio = 0.3;
          font = "Inter:size=12";
          width = 50;
        };
        #   prompt = "❯";
        #   width = 50;
        #   lines = 15;
        #   horizontal-pad = 20;
        #   vertical-pad = 10;
        #   inner-pad = 8;
        #   line-height = 24;
        #   image-size-ratio = 0.5;
        # };

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

    gtk = {
      enable = true;

      gtk4.extraCss = ''
        window {
          background-color: alpha(@window_bg_color, 0.8);
        }

        window > box,
        window > grid,
        window > overlay {
          background-color: alpha(@card_bg_color, 0.8);
        }

        .sidebar,
        .sidebar row,
        .navigation-sidebar {
          background-color: alpha(@view_bg_color, 0.9);
        }
      '';
    };

    home.pointerCursor = {
      enable = true;
      package = pkgs.graphite-cursors;
      name = "graphite-dark";
    };

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    # Polkit agent — Noctalia power actions (sleep/reboot/shutdown) call logind via D-Bus and need this
    services.hyprpolkitagent.enable = true;
  };
}
