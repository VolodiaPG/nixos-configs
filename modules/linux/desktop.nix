{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.desktop;
in {
  options = {
    services.desktop = with types; {
      enable = mkEnableOption "desktop";
    };
  };

  config = mkIf cfg.enable {
    #imports = [
    #  ../services/system76-scheduler/system76-scheduler.nix
    #];

    # Services
    # Enable the X11 windowing system.
    services = {
      xserver = {
        enable = true;
        layout = "fr";
        xkbVariant = "oss";
        xkbOptions = "eurosign:e,ctrl:swapcaps";

        displayManager.gdm = {
          enable = true;
          autoSuspend = false;
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
          '';
          extraGSettingsOverridePackages = [pkgs.gnome.gnome-settings-daemon];
        };
      };

      #system76Scheduler = {
      # enable = true;
      # assignments = builtins.readFile ./system76-assignments.ron;
      #};
      udev.packages = with pkgs; [gnome.gnome-settings-daemon];
      pipewire = {
        enable = true;
        alsa.enable = true;
        # alsa.support32Bit = true;
        pulse.enable = true;
        #  config.pipewire = {
        #   "context.properties" = {
        #    "resample.quality" = 15;
        #   "link.max-buffers" = 16;
        #  "default.clock.rate" = 96000;
        #  "default.clock.quantum" = 1024;
        #  "default.clock.min-quantum" = 32;
        #  "default.clock.max-quantum" = 8192;
        # };
        #};
      };
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

    #Enable ddc
    environment.systemPackages = with pkgs; [
      ddcutil
    ];

    services.udev.extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';
    # Load i2c kernel module
    boot.kernelModules = ["i2c-dev"];

    users.groups.i2c = {};

    users.users.volodia.extraGroups = ["i2c"];
    # Enable sound.

    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    programs = {
      dconf.enable = true;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-tty;
      };
    };

    fonts = {
      fonts = with pkgs; [
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
        #(callPackage ../../pkgs/comic-code {})
      ];
      fontconfig.defaultFonts = {
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
    };

    nixpkgs.config.joypixels.acceptLicense = true; # Personal use only

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
  };
}
