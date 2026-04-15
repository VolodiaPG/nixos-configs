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
      dconf = {
        enable = true;
        profiles.user.settings = {
          "org/gnome/shell" = {
            disable-user-extensions = false;
            disable-extension-version-validation = true;
            enabled-extensions = [
              "native-window-placement@gnome-shell-extensions.gcampax.github.com"
              "appindicatorsupport@rgcjonas.gmail.com"
              "pop-shell@system76.com"
              "Vitals@CoreCoding.com"
              "hide-activities-button@zeten30.com"
              "gnomeExtensions.gnome-40-ui-improvements@AXP.com"
              "gnome-ui-tune@itstime.tech"
              "Hide_Activities@shay.shayel.org"
              "RemoveAppMenu@Dragon8oy.com"
              "gsconnect@andyholmes.github.io"
              "BingWallpaper@ineffable-gmail.com"
              "blur-my-shell@aunetx"
              "rounded-window-corners@yilozt"
              "mediacontrols@cliffniff.github.com"
              "impatience@gfxmonk.net"
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "hibernate-status@dromi"
              "x11gestures@joseexposito.github.io"
              "display-brightness-ddcutil@themightydeity.github.com"
              "paperwm@paperwm.github.com"
              "tailscale-status@maxgallup.github.com"
              "just-perfection-desktop@just-perfection"
              "instantworkspaceswitcher@amalantony.net"
              "transparent-top-bar@ftpix.com"
            ];
          };

          "org/gnome/shell/extensions/net/gfxmonk/impatience" = {
            speed-factor = 0.5;
          };

          "org/gnome/shell/extensions/vitals" = {
            hot-sensors = [
              "_memory_usage_"
              "_memory_swap_usage_"
              "__network-tx_max__"
              "__network-rx_max__"
              "_processor_usage_"
              "_processor_frequency_"
              "_system_load_1m_"
              "__temperature_avg__"
              "_storage_free_"
            ];
            position-in-panel = 3;
          };

          "org/gnome/shell/extensions/pop-shell" = {
            "active-hint-border-radius" = "@u 15";
            "active-hint" = true;
            "mouse-cursor-follows-active-window" = true;
          };

          "org/gnome/mutter/wayland/keybindings" = {
            restore-shortcuts = [ ];
          };

          "org/gnome/desktop/wm/preferences" = {
            focus-mode = "click";
          };

          "org/gnome/desktop/sound" = {
            event-sounds = false;
          };

          "org/gnome/desktop/wm/keybindings" = {
            minimizere = [ ];
            switch-to-workspace-left = [ ];
            switch-to-workspace-right = [ ];
            maximize = [ ];
            unmaximize = [ ];
            move-to-monitor-up = [ ];
            move-to-monitor-down = [ ];
            move-to-monitor-left = [ ];
            move-to-workspace-left = [ ];
            move-to-workspace-down = [ ];
            move-to-workspace-up = [ ];
            move-to-monitor-right = [ ];
            move-to-workspace-right = [ ];
            switch-to-workspace-1 = [ "<Super>1" ];
            switch-to-workspace-2 = [ "<Super>2" ];
            switch-to-workspace-3 = [ "<Super>3" ];
            switch-to-workspace-4 = [ "<Super>4" ];
            switch-to-workspace-5 = [ "<Super>5" ];
            switch-to-workspace-6 = [ "<Super>6" ];
            switch-to-workspace-7 = [ "<Super>7" ];
            switch-to-workspace-8 = [ "<Super>8" ];
            switch-to-workspace-9 = [ "<Super>9" ];
            switch-to-workspace-10 = [ "<Super>0" ];
            switch-to-workspace-down = [ ];
            switch-to-workspace-up = [ ];
            toggle-maximized = [ ];
            close = [ "<Alt>f4" ];
          };

          "org/gnome/shell/keybindings" = {
            open-application-menu = [ ];
            toggle-message-tray = [ "<super>v" ];
            toggle-overview = [ ];
            switch-to-application-1 = [ ];
            switch-to-application-2 = [ ];
            switch-to-application-3 = [ ];
            switch-to-application-4 = [ ];
            switch-to-application-5 = [ ];
            switch-to-application-6 = [ ];
            switch-to-application-7 = [ ];
            switch-to-application-9 = [ ];
            switch-to-application-10 = [ ];
            open-new-window-application-1 = [ ];
            open-new-window-application-2 = [ ];
            open-new-window-application-3 = [ ];
            open-new-window-application-4 = [ ];
            open-new-window-application-5 = [ ];
            open-new-window-application-6 = [ ];
            open-new-window-application-7 = [ ];
            open-new-window-application-8 = [ ];
            open-new-window-application-9 = [ ];
            open-new-window-application-10 = [ ];
          };

          "org/gnome/mutter/keybindings" = {
            toggle-tiled-left = [ ];
            toggle-tiled-right = [ ];
          };

          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<super>t";
            command = "kgx";
            name = "Terminal";
          };

          "org/gnome/settings-daemon/plugins/media-keys" = {
            screensaver = [ "<super>escape" ];
            home = [ "<super>f" ];
            email = [ "<super>e" ];
            www = [ "<super>b" ];
            rotate-video-lock-static = [ ];
            next = [ "<Control><Alt><Super>space" ];
            play = [ "<Alt><Super>space" ];
            previous = [ "<Shift><Alt><Super>space" ];
            volume-down = [ "KP_Subtract" ];
            volume-up = [ "KP_Add" ];
            custom-keybindings = [
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            ];
          };

          "org/gnome/mutter" = {
            workspaces-only-on-primary = false;
          };

          "org/gnome/desktop/remote-desktop/rdp" = {
            screen-share-mode = "extend";
          };

          "org/gnome/shell/extensions/bingwallpaper" = {
            lockscreen-blur-brightness = 60;
            lockscreen-blur-strength = 2;
            override-lockscreen-blur = true;
            hide = true;
            selected-image = "current";
          };

          "org/gnome/shell/extensions/blur-my-shell/panel" = {
            blur = false;
          };

          "org/gnome/shell/extensions/blur-my-shell/applications" = {
            blur = false;
          };

          "org/gnome/shell/extensions/rounded-window-corners" = {
            global-rounded-corner-settings = "{'padding': <{'left': <uint32 1>, 'right': <uint32 1>, 'top': <uint32 1>, 'bottom': <uint32 1>}>, 'keep_rounded_corners': <{'maximized': <false>, 'fullscreen': <false>}>, 'border_radius': <uint32 20>, 'smoothing': <0.10000000000000001>, 'enabled': <true>}";
            settings-version = 5;
          };

          "org/gnome/desktop/interface" = {
            monospace-font-name = "Comic Code Ligatures";
          };

          "org/gnome/shell/extensions/mediacontrols" = {
            extension-position = "right";
            show-player-icon = true;
            show-separators = false;
            show-label = false;
            label-width = 0;
          };

          "org/gnome/shell/extensions/paperwm" = {
            "animation-time" = 0.025;
            "disable-scratch-in-overview" = false;
            "disable-topbar-styling" = false;
            "edge-preview-enable" = true;
            "minimap-scale" = 0.0;
            "minimap-shade-opacity" = 0;
            "only-scratch-in-overview" = false;
            "restore-attach-modal-dialogs" = "true";
            "restore-edge-tiling" = "true";
            "restore-workspaces-only-on-primary" = "false";
            "show-focus-mode-icon" = false;
            "show-open-position-icon" = false;
            "show-window-position-bar" = false;
            "show-workspace-indicator" = false;
            "use-default-background" = true;
            "window-switcher-preview-scale" = 0.05;
            "cycle-width-steps" = [
              0.49
              0.74
            ];
            "winprops" = [
              ''{"wm_class":"","title":"Picture in picture","scratch_layer":true,"focus":true}''
            ];
            "vertical-margin-bottom" = 0;
            "selection-border-size" = 0;
          };

          "org/gnome/shell/extensions/paperwm/keybindings" = {
            "resize-w-dec" = [ "<Super><Shift>minus" ];
            "resize-w-inc" = [ "<Super><Shift>plus" ];
            "resize-h-dec" = [ ];
            "resize-h-inc" = [ ];
            "cyle-width" = [ "<Super>r" ];
            "switch-down" = [
              "<Super>Down"
              "<Super>j"
            ];
            "switch-left" = [
              "<Super>Left"
              "<Super>h"
            ];
            "switch-right" = [
              "<Super>Right"
              "<Super>l"
            ];
            "switch-up" = [
              "<Super>Up"
              "<Super>k"
            ];
          };

          "org/gnome/shell/extensions/just-perfection" = {
            "top-panel-position" = 1;
            "animation" = 3;
          };

          "com/ftpix/transparentbar" = {
            "dark-full-screen" = false;
            "disable-text-shadow" = true;
            "transparency" = 0;
          };
        };
      };
    };
  };
}
