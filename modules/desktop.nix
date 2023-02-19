{ config, pkgs, pkgs-unstable, ... }:
{
  imports = [
    ../services/system76-scheduler/system76-scheduler.nix
  ];

  # Services
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm = {
  #   enable = true;
  #   autoSuspend = false;
  # };
  # services.xserver.desktopManager.gnome = {
  #   enable = true;
  #   # Override GNOME defaults to disable GNOME tour and disable suspend
  #   extraGSettingsOverrides = ''
  #     [org.gnome.desktop.session]
  #     idle-delay=0
  #     [org.gnome.settings-daemon.plugins.power]
  #     sleep-inactive-ac-type='nothing'
  #     sleep-inactive-battery-type='nothing'
  #   '';
  #   extraGSettingsOverridePackages = [ pkgs.gnome.gnome-settings-daemon ];
  # };

  services.lorri.enable = true; # fast direnv

  # Configure keymap in X11
  services.xserver = {
    layout = "fr";
    xkbVariant = "oss";
    xkbOptions = "eurosign:e";
  };

  # services.system76Scheduler = {
  #   enable = true;
  #   assignments = builtins.readFile ./system76-assignments.ron;
  # };

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

    distrobox

    # Gnome extensions
    # gnomeExtensions.appindicator
    # gnomeExtensions.vitals
    # gnomeExtensions.pop-shell
    # gnomeExtensions.hide-activities-button
    # gnomeExtensions.remove-app-menu
    # gnomeExtensions.gnome-40-ui-improvements
    # gnomeExtensions.gsconnect
    # gnomeExtensions.bing-wallpaper-changer
    # gnomeExtensions.blur-my-shell
    # gnomeExtensions.rounded-window-corners
    # gnomeExtensions.media-controls
    # gnomeExtensions.impatience

    # Browser
    # firefox-beta-bin
    brave
    chromium
    # tor-browser-bundle-bin

    # lapce
    (pkgs-unstable.vscode-with-extensions.override {
      vscodeExtensions = with pkgs-unstable.vscode-extensions; [
        # vadimcn.vscode-lldb
        matklad.rust-analyzer
        jnoortheen.nix-ide
        # ms-python.python
        skellock.just
        arrterian.nix-env-selector
        eamodio.gitlens
        usernamehw.errorlens
      ] ++ pkgs-unstable.vscode-utils.extensionsFromVscodeMarketplace [
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
    # bottles
    # boxes

    spice-vdagent # copy paste for vms
  ];

  fonts.fonts = with pkgs; [
    # powerline-fonts
    corefonts
    # noto-fonts
    # noto-fonts-cjk
    # noto-fonts-emoji
    # noto-fonts-extra
    # ubuntu_font_family
    roboto
    joypixels
    # nerdfonts
    (callPackage ../pkgs/comic-code { })
  ];

  nixpkgs.config.joypixels.acceptLicense = true; # Personal use only

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Comic Code Ligatures"
    ];

    sansSerif = [
      "Roboto"
      # "Noto Sans"
      # "Noto Sans CJK JP"
    ];

    # serif = [
    #   "Noto Serif"
    #   "Noto Serif CJK JP"
    # ];
  };

  # virtualisation.libvirtd.enable = true;
  # virtualisation = {
  #   waydroid.enable = true;
  #   # lxd.enable = true;
  # };

  # services.gnome.gnome-remote-desktop.enable = true;

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

  # qt = {
  #   enable = true;
  #   platformTheme = "kde";
  # };
}
