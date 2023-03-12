{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../services/system76-scheduler/system76-scheduler.nix
  ];

  # Services
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
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
    extraGSettingsOverridePackages = [pkgs.gnome.gnome-settings-daemon];
  };

  environment.gnome.excludePackages =
    (with pkgs; [
      gnome-photos
      gnome-tour
      gnome-connections # Replaced by Remmina
      orca
    ])
    ++ (with pkgs.gnome; [
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
  # services.touchegg.enable = true;
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
        "default.clock.rate" = 96000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 8192;
      };
    };
  };

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };
  };

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
    (callPackage ../pkgs/comic-code {})
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
      {
        from = 6881;
        to = 6999;
      } # Torrents
      {
        from = 1714;
        to = 1764;
      } # KDEConnect
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDEConnect
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
}
