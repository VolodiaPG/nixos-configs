{ config, pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (import ../dotfiles/default.nix)
  ];
  imports = [
    <home-manager/nixos>
    ../pkgs/symlinks/default.nix
    ../services/system76-scheduler/system76-scheduler.nix
    (fetchTarball "https://github.com/takagiy/nixos-declarative-fish-plugin-mgr/archive/0.0.5.tar.gz")
  ];

  # Services
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "fr";
    xkbVariant = "oss";
    xkbOptions = "eurosign:e";
  };

  services.system76Scheduler.enable = true;

  # Enable sound.
  hardware.pulseaudio.enable = false;
  sound.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    config.pipewire = {
      "context.properties" = {
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
    gnome-maps
    gnome-contacts
  ]);

  home-manager.users.volodia = { pkgs, ... }: {
    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
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
          ];
        };

        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = [ "_memory_usage_" "__network-tx_max__" "__network-rx_max__" "_processor_usage_" "_processor_frequency_" "_system_load_1m_" "__temperature_avg__" ];
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
          terminal = [ "<super>t" ];
          # rotate video lock
          rotate-video-lock-static = [ ];
        };
        "org/gnome/mutter" = {
          workspaces-only-on-primary = false;
        };
      };
    };
  };

   programs.fish = {
    # 2. Enable fish-shell if you didn't.
    enable = true;

    # 3. Declare fish plugins to be installed.
    plugins = [
      "jethrokuan/fzf"
      "b4b4r07/enhancd"
      # "IlanCosman/tide"
    ];
  };

  environment.systemPackages = with pkgs; [
    # Fish deps
    fzf # Required by jethrokuan/fzf.
    fzy # Required by b4b4r07/enhancd.

    # Gnome extensions
    gnomeExtensions.appindicator
    gnomeExtensions.vitals
    gnomeExtensions.pop-shell
    gnomeExtensions.hide-activities-button
    gnomeExtensions.remove-app-menu
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.gsconnect

    # Browser
    firefox-beta-bin

    # Media
    (mpv-with-scripts.override { scripts = [ mpvScripts.mpris ]; })
    tidal-hifi
    libsForQt5.qt5.qtwayland # Allow SVP to run on wayland
    (pkgs.callPackage ../pkgs/svp { })
    # (pkgs.callPackage ../pkgs/system76-scheduler { })

    # Chat
    discord

    # Development
    nixpkgs-fmt # Nix formatter
    vscode
    insomnia
    gitui

    # VM dependencies
    # qemu_kvm
    # qemu
    # libvirt
    # bridge-utils
    # virt-manager
    # virt-viewer
    # spice-vdagent
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

  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
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

  users.users.volodia.symlinks = {
    ".gitconfig" = pkgs.gitconfig;
  };

  nixpkgs.config.packageOverrides = pkgs: rec {
    # mistune = pkgs.mistune_2_0;
    mpv = (pkgs.mpv-unwrapped.override {
      vapoursynthSupport = true;
      vapoursynth = pkgs.vapoursynth;
    }).overrideAttrs (old: rec {
      wafConfigureFlags = old.wafConfigureFlags ++ [ "--enable-vapoursynth" ];
    });
  };

  virtualisation.libvirtd.enable = true;

  # Open up ports
  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 6881; to = 6999; } # Torrents
      { from = 1714; to = 1764; } # KDEConnect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDEConnect
    ];
  };

  # Enable bluetooth.
  # hardware.bluetooth = {
  #   enable = true;
  #   package = pkgs.bluezFull;
  #   settings.General.Enable = "Source,Sink,Media,Socket";
  # };
}
