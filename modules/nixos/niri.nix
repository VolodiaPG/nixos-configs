{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) package;
  cfg = config.services.wm.niri;
in
{
  options = {
    services.wm.niri = {
      enable = mkEnableOption "niri - scrollable-tiling Wayland compositor";

      package = mkOption {
        type = package;
        default = pkgs.niri;
        description = "The niri package to use";
      };
    };
  };

  config = mkIf cfg.enable {
    programs = {
      # Enable niri session
      niri = {
        enable = true;
        useNautilus = true;
        inherit (cfg) package;
      };
      # Make sure GTK applications work properly
      xwayland.enable = true;
      # Enable dconf for settings management
      dconf.enable = true;
    };

    # Enable display manager with niri support
    services = {
      # Display manager for niri (since GNOME/GDM is disabled)
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
            user = "greeter";
          };
        };
      };

      displayManager = {
        sessionPackages = [ cfg.package ];
        # Use greetd or similar minimal DM, or allow direct launch
        # Users can override this in their host config
      };

      # Fix nautilus network share
      gvfs.enable = true;
    };

    # Required for Wayland compositors
    hardware.graphics.enable = true;

    # Basic system packages for niri functionality
    environment.systemPackages = [
      # Screenshot utilities
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard

      # Polkit agent for authentication dialogs
      pkgs.polkit_gnome

      # File manager integration
      pkgs.xdg-utils

      # Idle management
      pkgs.swayidle
      # swaylock

      # Clipboard manager
      pkgs.cliphist
    ];
    # # Enable xdg portal for screen sharing and other integrations
    # xdg.portal = {
    #   enable = true;
    #   extraPortals = [
    #     pkgs.xdg-desktop-portal-gtk
    #     pkgs.xdg-desktop-portal-gnome
    #     pkgs.xdg-desktop-portal-wlr
    #   ];
    #   # config.common.default = "*";
    #   # Portal Configuration
    #   config = {
    #     # 'common' applies to all desktops unless overridden
    #     common = {
    #       default = [ "gtk" ];
    #       "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    #     };
    #
    #     niri = {
    #       "org.freedesktop.impl.portal.Access" = "gtk";
    #       "org.freedesktop.impl.portal.FileChooser" = "gtk";
    #       "org.freedesktop.impl.portal.Notification" = "gtk";
    #       "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    #     };
    #   };
    # };

    # Polkit for privilege escalation
    security.polkit.enable = true;

    # Basic services for Wayland compositor
    services = {
      # GNOME keyring for secrets
      gnome.gnome-keyring.enable = true;

      # Power management (required for Noctalia battery widget)
      upower.enable = true;

      # Locale/location
      geoclue2.enable = true;
    };

    # Note: power-profiles-daemon is optional for Noctalia's power-profile widget.
    # If using TLP instead, the widget will display TLP's power profile information.

    # Network management (required for Noctalia wifi widget)
    networking.networkmanager.enable = true;

    # Bluetooth support (required for Noctalia bluetooth widget)
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
