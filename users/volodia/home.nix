{ pkgs, overlays, ... }:
{
  nixpkgs.overlays = overlays;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "volodia";
  home.homeDirectory = "/home/volodia";

  programs.nix-index =
    {
      enable = true;
      enableFishIntegration = true;
    };

  programs.fish = {
    # 2. Enable fish-shell if you didn't.
    enable = true;

    # 3. Declare fish plugins to be installed.
    plugins = [
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "fzf";
          rev = "479fa67d7439b23095e01b64987ae79a91a4e283";
          sha256 = "sha256-28QW/WTLckR4lEfHv6dSotwkAKpNJFCShxmKFGQQ1Ew=";
        };
      }
      { name = "grc"; inherit (pkgs.fishPlugins.grc) src; }
      { name = "done"; inherit (pkgs.fishPlugins.done) src; }
      { name = "pure"; inherit (pkgs.fishPlugins.pure) src; }
    ];

    shellAliases = {
      cd = "z";
      ll = "ls -l";
      l = "ls";
      push = "git push";
      pull = "git pull";
      fetch = "git fetch";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs;
    [
      # Gnome extensions
      gnomeExtensions.appindicator
      gnomeExtensions.vitals
      gnomeExtensions.pop-shell
      gnomeExtensions.hide-activities-button
      gnomeExtensions.remove-app-menu
      gnomeExtensions.gnome-40-ui-improvements
      gnomeExtensions.gsconnect
      gnomeExtensions.bing-wallpaper-changer
      gnomeExtensions.blur-my-shell
      gnomeExtensions.rounded-window-corners
      gnomeExtensions.media-controls
      gnomeExtensions.impatience
      gnomeExtensions.hibernate-status-button
      gnomeExtensions.x11-gestures
    ];


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
          "remove-app-menu@stuarthayhurst.com"
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
        ];
      };

      "org/gnome/shell/extensions/vitals" = {
        hot-sensors = [ "_memory_usage_" "__network-tx_max__" "__network-rx_max__" "_processor_usage_" "_processor_frequency_" "_system_load_1m_" "__temperature_max__" ];
        position-in-panel = 3;
      };

      "org/gnome/shell/extensions/pop-shell" = {
        "active-hint-border-radius" = 20;
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
        minimize = [ ];
        # switch to workspace left: disable <super>left
        switch-to-workspace-left = [ "<primary><super>left" ];
        # switch to workspace right: disable <super>right
        switch-to-workspace-right = [ "<primary><super>right" ];
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
        move-to-workspace-left = [ "<primary><super><shift>left" ];
        # move window one workspace down
        move-to-workspace-down = [ ];
        # move window one workspace up
        move-to-workspace-up = [ ];
        # move window one monitor to the right
        move-to-monitor-right = [ ];
        move-to-workspace-right = [ "<primary><super><shift>right" ];
        # super + ctrl + direction keys, change workspaces, move focus between monitors
        # move to workspace below
        switch-to-workspace-down = [ "<primary><super>down" "<primary><super>j" ];
        # move to workspace above
        switch-to-workspace-up = [ "<primary><super>up" "<primary><super>k" ];
        # toggle maximization state
        toggle-maximized = [ ];
        # close window
        close = [ "<super>q" "<alt>f4" ];
      };
      "org/gnome/shell/keybindings" = {
        open-application-menu = [ ];
        # toggle message tray: disable <super>m
        toggle-message-tray = [ "<super>v" ];
        # show the activities overview: disable <super>s
        toggle-overview = [ ];
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
        custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
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
        whitelist = [ "Kgx" "org.gnome.Console" "Org.gnome.Nautilus" "Code" "gnome-control-center" "tidal-hifi" "discord" "lapce" ];
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
        show-player-icon = false;
        show-separators = false;
      };
    };
  };
  gtk = {
    enable = true;

    iconTheme = {
      name = "Pop";
      package = pkgs.pop-icon-theme;
    };

    theme = {
      name = "Pop";
      package = pkgs.pop-gtk-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

  };
  home.sessionVariables.GTK_THEME = "popos";

  home.file.".config/discord/settings.json".text = ''
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

  home.file.".config/mpv" = {
    source = ./mpv;
    recursive = true;
  };
  home.file.".config/mpv/svp.py".source = pkgs.substituteAll {
    src = ./svp.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };
  home.file.".config/mpv/svp_max.py".source = pkgs.substituteAll {
    src = ./svp_max.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };
  home.file.".config/mpv/svp_nvof.py".source = pkgs.substituteAll {
    src = ./svp_nvof.py;
    svpflow = "${pkgs.svpflow}/lib/";
  };

  home.file.".ssh/config".source = pkgs.substituteAll {
    src = ./config.ssh;
    g5k_login = builtins.readFile ../../secrets/grid5000.user;
  };
  home.file.".python-grid5000.yaml".source = ../../secrets/python-grid5000.yaml;

  home.file.".tmux".text = ''
    set -g mouse

    bind C-c run "tmux save-buffer - | wl-copy"

    bind C-v run "tmux set-buffer "$(wl-paste)"; tmux paste-buffer"
  '';

  programs.git = {
    enable = true;
    userName = "Volodia P.-G.";
    userEmail = builtins.readFile ../../secrets/gitmail;
    signing = {
      key = builtins.readFile ../../secrets/gitkeyid;
      signByDefault = true;
    };
    extraConfig = {
      rebase.autostash = true;
      init.defaultBranch = "main";
      core.editor = "micro";
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";
}
