{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) package;
  cfg = config.services.wm.hyprland;
in
{
  # ponytail: noctalia module only exists in unstable nixpkgs — import it from there
  # while the system stays on stable. Package is provided via the unstable overlay.
  imports = [
    (flake.inputs.nixpkgs-unstable.outPath + "/nixos/modules/programs/wayland/noctalia.nix")
  ];

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
        withUWSM = true;
        inherit (cfg) package;
      };

      noctalia = {
        enable = true;
        systemd.enable = true;
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
            # ponytail: launch via uwsm so systemd user graphical-session.target comes up.
            # Bypassing it (plain start-hyprland) left the target dead, so hyprpolkitagent and
            # the noctalia systemd service never started and power buttons no-op'd (no polkit
            # agent + caller outside session scope → auth_admin_keep with no agent to satisfy).
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop'";
            user = "greeter";
          };
        };
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
