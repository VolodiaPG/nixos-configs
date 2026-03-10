{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.wm.niri;
in
{
  options = {
    services.wm.niri = with types; {
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
      displayManager = {
        sessionPackages = [ cfg.package ];
        # Use greetd or similar minimal DM, or allow direct launch
        # Users can override this in their host config
      };

      # Fix nautilus network share
      gvfs.enable = true;

      # Wallpaper
      fractalart.enable = true;
    };

    # Required for Wayland compositors
    hardware.graphics.enable = true;

    # Basic system packages for niri functionality
    environment.systemPackages = with pkgs; [
      # Screenshot utilities
      grim
      slurp
      wl-clipboard

      # Polkit agent for authentication dialogs
      polkit_gnome

      # File manager integration
      xdg-utils

      # Idle management
      swayidle
      # swaylock

      # Clipboard manager
      cliphist
    ];

    # Enable xdg portal for screen sharing and other integrations
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-wlr
      ];
      config.common.default = "*";
    };

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
