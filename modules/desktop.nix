{ config, pkgs, pkgs-unstable, ... }:
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
  services.touchegg.enable = true;

  environment.systemPackages = with pkgs; [
    remmina
    cloudflare-warp
    veracrypt
    pavucontrol

    distrobox

    powerstat

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
    libreoffice
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
    # boxes

    spice-vdagent # copy paste for vms
  ] ++ [
    pkgs-unstable.bottles
    pkgs-unstable.lapce
    pkgs-unstable.powertop
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
