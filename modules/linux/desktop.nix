{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.desktop;
in
{
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

    programs.cfs-zen-tweaks.enable = true;

    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = false;
      xserver = {
        enable = lib.mkForce true;
        xkb = {
          variant = "oss";
          options = "eurosign:e,ctrl:swapcaps";
          layout = "fr";
        };

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
      };
      system76-scheduler = {
        enable = false;
        useStockConfig = true;
      };

      #system76Scheduler = {
      # enable = true;
      # assignments = builtins.readFile ./system76-assignments.ron;
      #};
      udev.packages = with pkgs; [ gnome-settings-daemon ];

      pipewire = {
        enable = true;

        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        extraConfig = {
          pipewire = {
            "92-low-latency" = {
              context.properties.default.clock = {
                # resample.quality = 15;
                # link.max-buffers = 16;
                rate = 192000;
                quantum = 32;
                min-quantum = 32;
                max-quantum = 8192;
              };
            };
            "93-alsa-config" = {
              context.objects = [
                {
                  factory = "adapter";
                  args = {
                    factory.name = "api.alsa.pcm.sink";
                    node = {
                      name = "alsa-sink";
                      description = "High-Quality ALSA Sink";
                    };
                    media.class = "Audio/Sink";
                    # api.alsa.path = "hw:0,0"; # Adjust for your DAC
                    api.alsa = {
                      period-size = 32;
                      headroom = 0;
                      channels = 2;
                    };
                    audio = {
                      format = "S24_3LE"; # 24-bit
                      rate = 192000;
                      channels = 2;
                      position = [
                        "FL"
                        "FR"
                      ];
                    };
                  };
                }
              ];
            };
          };

          pipewire-pulse."92-low-latency" = {
            context.modules = [
              {
                name = "libpipewire-module-protocol-pulse";
                args.pulse = {
                  min.req = "32/192000";
                  default.req = "32/192000";
                  max.req = "32/192000";
                  min.quantum = "32/192000";
                  max.quantum = "8192/192000";
                };
              }
            ];
            stream.properties = {
              node.latency = "32/192000";
              resample = {
                quality = 15;
                disable = true;
              };
              channelmix = {
                disable = false;
                min-volume = 0.0;
                max-volume = 10.0;
              };
            };
          };
        };
      };
    };

    boot.kernelParams = [
      "snd-hda-intel.power_save=0" # Disable power saving
      "snd-ac97-codec.power_save=0"
    ];

    # Real-time scheduling for audio
    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];

    # Add user to audio group

    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
        gnome-connections # Replaced by Remmina
        orca
      ])
      ++ (with pkgs; [
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
    boot.kernelModules = [ "i2c-dev" ];

    users.groups.i2c = { };

    users.users.volodia.extraGroups = [ "i2c" ];
    # Enable sound.
    programs = {
      dconf.enable = true;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-tty;
      };
    };

    fonts = {
      packages = with pkgs; [
        # powerline-fonts
        corefonts
        # noto-fonts
        # noto-fonts-cjk
        # noto-fonts-emoji
        # noto-fonts-extra
        # ubuntu_font_family
        roboto
        joypixels
        nerd-fonts.iosevka-term
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

    services.kanata = {
      enable = true;
      keyboards.all.config = readFile ./kanata.lisp;
      keyboards.all.extraDefCfg = ''
        concurrent-tap-hold yes
      '';
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
  };
}
