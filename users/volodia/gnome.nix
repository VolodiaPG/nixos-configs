{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
{
  home.packages = with pkgs; [
    # Gnome extensions
    gnomeExtensions.appindicator
    gnomeExtensions.vitals
    # gnomeExtensions.pop-shell
    # gnomeExtensions.hide-activities-button
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.gsconnect
    gnomeExtensions.bing-wallpaper-changer
    gnomeExtensions.blur-my-shell
    gnomeExtensions.media-controls
    # gnomeExtensions.impatience
    gnomeExtensions.hibernate-status-button
    gnomeExtensions.brightness-control-using-ddcutil
    gnomeExtensions.paperwm
    gnomeExtensions.tailscale-status
    gnomeExtensions.just-perfection
    gnomeExtensions.disable-workspace-switch-animation-for-gnome-40

    gnome-obfuscate

    brave
    pkgs-unstable.tidal-hifi
    hyperhdr
    distrobox
    distrobox-tui
    kitty
    discord
    signal-desktop
    gnome-tweaks
    qpdfview
    strawberry
    qbittorrent
    distrobox
    vlc
    nur.repos.Ev357.helium
    # orca-slicer
  ];
  xdg.desktopEntries = {
    OrcaSlicer = {
      name = "OrcaSlicer";
      genericName = "3D Printing Software";
      icon = "OrcaSlicer";
      exec = lib.concatStringsSep " " [
        "${pkgs.coreutils}/bin/env"
        "__GLX_VENDOR_LIBRARY_NAME=mesa"
        "__EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
        "MESA_LOADER_DRIVER_OVERRIDE=zink"
        "GALLIUM_DRIVER=zink"
        "WEBKIT_DISABLE_DMABUF_RENDERER=1"
        "${lib.getExe pkgs.orca-slicer} %U"
      ];
      terminal = false;
      type = "Application";
      mimeType = [
        "model/stl"
        "model/3mf"
        "application/vnd.ms-3mfdocument"
        "application/prs.wavefront-obj"
        "application/x-amf"
      ];
      categories = [
        "Graphics"
        "3DGraphics"
        "Engineering"
      ];
      startupNotify = false;
    };
  };
  # can use the gnome dump command
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        disable-extension-version-validation = true;
        enabled-extensions = [
          # cosmic-dock needs dash-to-dock
          #dash-to-dock@micxgx.gmail.com"
          #"cosmic-dock@system76.com"

          "native-window-placement@gnome-shell-extensions.gcampax.github.com"

          #"user-theme@gnome-shell-extensions.gcampax.github.com"
          #"workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          "appindicatorsupport@rgcjonas.gmail.com"
          "pop-shell@system76.com"
          #"cosmic-workspaces@system76.com"
          # "pop-cosmic@system76.com"
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

      # disable incompatible shortcuts
      "org/gnome/mutter/wayland/keybindings" = {
        # restore the keyboard shortcuts: disable <super>escape
        restore-shortcuts = [ ];
      };
      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "mouse";
      };
      "org/gnome/desktop/wm/keybindings" = {
        # hide window: disable <super>h
        minimizere = [ ];
        # switch to workspace left: disable <super>left
        switch-to-workspace-left = [ ];
        # switch to workspace right: disable <super>right
        switch-to-workspace-right = [ ];
        # maximize window: disable <super>up
        maximize = [ ];
        # restore window: disable <super>down
        unmaximize = [ ];
        # move to monitor up: disable <super><shift>up
        move-to-monitor-up = [ ];
        # move to monitor down: disable <super><shift>down
        move-to-monitor-down = [ ];
        # super + direction keys, move window left and right monitors, or up and down workspaces
        # move window one monitor to the left
        move-to-monitor-left = [ ];
        move-to-workspace-left = [ ];
        # move window one workspace down
        move-to-workspace-down = [ ];
        # move window one workspace up
        move-to-workspace-up = [ ];
        # move window one monitor to the right
        move-to-monitor-right = [ ];
        move-to-workspace-right = [ ];
        switch-to-workspace-1 = [
          "<Super>1"
        ];
        switch-to-workspace-2 = [
          "<Super>2"
        ];
        switch-to-workspace-3 = [
          "<Super>3"
        ];
        switch-to-workspace-4 = [
          "<Super>4"
        ];
        switch-to-workspace-5 = [
          "<Super>5"
        ];
        switch-to-workspace-6 = [
          "<Super>6"
        ];
        switch-to-workspace-7 = [
          "<Super>7"
        ];
        switch-to-workspace-8 = [
          "<Super>8"
        ];
        switch-to-workspace-9 = [
          "<Super>9"
        ];
        switch-to-workspace-10 = [
          "<Super>0"
        ];
        # super + ctrl + direction keys, change workspaces, move focus between monitors
        # move to workspace below
        switch-to-workspace-down = [
        ];
        # move to workspace above
        switch-to-workspace-up = [
        ];
        # toggle maximization state
        toggle-maximized = [ ];
        # close window
        close = [
          # "<super>q"
          "<Alt>f4"
        ];
      };
      "org/gnome/shell/keybindings" = {
        open-application-menu = [ ];
        # toggle message tray: disable <super>m
        toggle-message-tray = [ "<super>v" ];
        # show the activities overview: disable <super>s
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
        # disable tiling to left / right of screen
        toggle-tiled-left = [ ];
        toggle-tiled-right = [ ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<super>t";
        command = "kgx";
        name = "Terminal";
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        # lock screen
        screensaver = [ "<super>escape" ];
        # home folder
        home = [ "<super>f" ];
        # launch email client
        email = [ "<super>e" ];
        # launch web browser
        www = [ "<super>b" ];
        # launch terminal
        # terminal = [ "<super>t" ];
        # rotate video lock
        rotate-video-lock-static = [ ];
        # Next trac
        next = [ "<Control><Alt><Super>space" ];
        play = [ "<Alt><Super>space" ];
        previous = [ "<Shift><Alt><Super>space" ];
        volume-down = [ "KP_Subtract" ];
        volume-up = [ "KP_Add" ];
        # Terminal
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
      "org/gnome/shell/extensions/blur-my-shell/applications" = {
        blur = false;
        opacity = 230;
        whitelist = [
          "Kgx"
          "org.gnome.Console"
          "Org.gnome.Nautilus"
          "Code"
          "gnome-control-center"
          "tidal-hifi"
          "discord"
          "lapce"
        ];
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
          0.24
          0.49
          0.74
        ];
        "winprops" = [
          ''{"wm_class":"","title":"Picture in picture","scratch_layer":true,"focus":true}''
        ];
      };
      "org/gnome/shell/extensions/paperwm/keybindings" = {
        "resize-w-dec" = [
          "<Super><Shift>minus"
        ];
        "resize-w-inc" = [
          "<Super><Shift>plus"
        ];
        "resize-h-dec" = [ ];
        "resize-h-inc" = [ ];
        "cyle-width" = [
          "<Super>r"
        ];
        "switch-down" = [
          "<Super>Down"
          "<Super>j"
          # "<Alt>Down"
          # "<Alt>j"
        ];
        "switch-left" = [
          "<Super>Left"
          "<Super>h"
          # "<Alt>Left"
          # "<Alt>h"
        ];
        "switch-right" = [
          "<Super>Right"
          "<Super>l"
          # "<Alt>Right"
          # "<Alt>l"
        ];
        "switch-up" = [
          "<Super>Up"
          "<Super>k"
          # "<Alt>Up"
          # "<Alt>k"
        ];
      };
      "org/gnome/shell/extensions/just-perfection" = {
        "top-panel-position" = 1;
        "animation" = 3;
      };
    };
  };
  gtk = {
    enable = true;

    # iconTheme = {
    #   name = "WhiteSur";
    #   package = pkgs.whitesur-icon-theme.override {
    #     alternativeIcons = true;
    #     boldPanelIcons = true;
    #   };
    # };
    cursorTheme = {
      name = "phinger-cursors-light";
      package = pkgs.phinger-cursors;
      size = 24;
    };
    # theme = {
    #   name = "Jasper";
    #   package = pkgs.jasper-gtk-theme;
    # };
  };

  # qt = {
  #   #enable = true;
  #   platformTheme = "kvantum";
  #   style.name = "kvantum";
  # };
}
