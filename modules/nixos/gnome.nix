{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.wm.gnome;
in
{
  options = {
    services.wm.gnome = with types; {
      enable = mkEnableOption "gnome";
    };
  };

  config = mkIf cfg.enable {
    services = {
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
        wayland = true;
      };

      desktopManager.gnome = {
        enable = true;
        # Override GNOME defaults to disable GNOME tour and disable suspend
        extraGSettingsOverrides = ''
          [org.gnome.desktop.session]
          idle-delay=0
          [org.gnome.settings-daemon.plugins.power]
          sleep-inactive-ac-type='nothing'
          sleep-inactive-battery-type='nothing'
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer']
          [org.gnome.SessionManager]
          auto-save-session=true
          [org.gtk.Settings.FileChooser]
          sort-directories-first=true
        '';
        extraGSettingsOverridePackages = [
          pkgs.mutter
          pkgs.gnome-settings-daemon
        ];
      };

      udev.packages = [ pkgs.gnome-settings-daemon ];

      gnome.core-apps.enable = false;
    };

    # Enable sound.
    programs = {
      dconf.enable = true;
    };
  };
}
