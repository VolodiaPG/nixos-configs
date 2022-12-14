{ config, pkgs, home-manager, ... }:
{
  imports = [
    ../services/system76-scheduler/system76-scheduler.nix
  ];

  # Services
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };
  services.xserver.desktopManager.gnome = {
    enable = true;
    # Override GNOME defaults to disable GNOME tour and disable suspend
    extraGSettingsOverrides = ''
      [org.gnome.desktop.session]
      idle-delay=0
      [org.gnome.settings-daemon.plugins.power]
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-type='nothing'
    '';
    extraGSettingsOverridePackages = [ pkgs.gnome.gnome-settings-daemon ];
  };

  services.lorri.enable = true; # fast direnv

  # Configure keymap in X11
  services.xserver = {
    layout = "fr";
    xkbVariant = "oss";
    xkbOptions = "eurosign:e";
  };

  services.system76Scheduler = {
    enable = true;
    assignments = builtins.readFile ./system76-assignments.ron;
  };

  # Enable sound.
  hardware.pulseaudio.enable = false;
  sound.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;
    config.pipewire = {
      "context.properties" = {
        "resample.quality" = 15;
        "link.max-buffers" = 16;
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 8192;
      };
    };
  };

  # Thermal management
  services.thermald.enable = true;

  # ACPId
  services.acpid.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-connections # Replaced by Remmina
    orca
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gnome-terminal
    epiphany # web browser
    geary # email reader
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    yelp
    gnome-logs
    gnome-maps
    gnome-contacts
  ]);

  home-manager.users.volodia = _: {
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
  };

  environment.systemPackages = with pkgs; [
    # Fish deps
    fzf # Required by jethrokuan/fzf.
    grc
    libnotify
    notify-desktop
    tmux

    bottom # call btm
    libgtop
    lm_sensors

    remmina
    cloudflare-warp
    veracrypt
    pavucontrol

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

    # Browser
    firefox-beta-bin
    tor-browser-bundle-bin

    lapce
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        vadimcn.vscode-lldb
        matklad.rust-analyzer
        jnoortheen.nix-ide
        ms-python.python
        skellock.just
        arrterian.nix-env-selector
        eamodio.gitlens
        usernamehw.errorlens
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          publisher = "vscode-icons-team";
          name = "vscode-icons";
          version = "12.0.1";
          sha256 = "sha256-zxKD+8PfuaBaNoxTP1IHwG+25v0hDkYBj4RPn7mSzzU=";
        }
        {
          publisher = "teabyii";
          name = "ayu";
          version = "1.0.5";
          sha256 = "sha256-+IFqgWliKr+qjBLmQlzF44XNbN7Br5a119v9WAnZOu4=";
        }
        {
          publisher = "iliazeus";
          name = "vscode-ansi";
          version = "1.1.2";
          sha256 = "sha256-sQfaykUy3bqL2QFicxR6fyZQtOXtL/BqV0dbAPMh+lA=";
        }
      ];
    })

    # Office
    # libreoffice-fresh
    xournalpp
    zotero

    # Media
    tidal-hifi
    libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
    mpv
    vlc

    # Chat
    discord
    signal-desktop

    # Development
    nixpkgs-fmt # Nix formatter
    insomnia
    gitui

    # Utils
    bottles
    boxes

    spice-vdagent # copy paste for vms
  ];

  fonts.fonts = with pkgs; [
    powerline-fonts
    corefonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    nerdfonts
    ipafont
    (callPackage ../pkgs/comic-code { })
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Comic Code Ligatures"
      "Hack Nerd Font"
      "Noto Sans Mono CJK JP"
    ];

    sansSerif = [
      "Noto Sans"
      "Noto Sans CJK JP"
    ];

    serif = [
      "Noto Serif"
      "Noto Serif CJK JP"
    ];
  };

  # virtualisation.libvirtd.enable = true;
  virtualisation = {
    waydroid.enable = true;
    lxd.enable = true;
  };

  services.gnome.gnome-remote-desktop.enable = true;

  # Open up ports
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      { from = 6881; to = 6999; } # Torrents
      { from = 1714; to = 1764; } # KDEConnect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDEConnect
    ];
    allowedTCPPorts = [
      22 # SSH
      3389 # RDP
    ];
    allowedUDPPorts = [
      3389 # RDP
      5353 # mDNS, avahi
    ];
  };

  qt5 = {
    enable = true;
    platformTheme = "gnome";
  };
}
