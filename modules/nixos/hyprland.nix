{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) package;
  cfg = config.services.wm.hyprland;
in
{
  options = {
    services.wm.hyprland = {
      enable = mkEnableOption "hyprland - scrollable-tiling Wayland compositor";

      package = mkOption {
        type = package;
        default = pkgs.hyprland;
        description = "The hyprland package to use";
      };
    };
  };

  config = mkIf cfg.enable {
    programs = {
      # Enable hyprland session
      hyprland = {
        enable = true;
        inherit (cfg) package;
      };
      # Make sure GTK applications work properly
      xwayland.enable = true;
      # Enable dconf for settings management
      dconf.enable = true;
    };

    # Enable display manager with hyprland support
    services = {
      # Display manager for hyprland (since GNOME/GDM is disabled)
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
            user = "greeter";
          };
        };
      };

      displayManager = {
        sessionPackages = [ cfg.package ];
      };

      # Fix nautilus network share
      gvfs.enable = true;
    };

    # Required for Wayland compositors
    hardware.graphics.enable = true;

    # Basic system packages for hyprland functionality
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

      # Clipboard manager
      pkgs.cliphist
    ];

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

    # Network management (required for Noctalia wifi widget)
    networking.networkmanager.enable = true;

    # Bluetooth support (required for Noctalia bluetooth widget)
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
