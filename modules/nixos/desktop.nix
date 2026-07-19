{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.wm;
  kanataConfigPath = flake.self + "/static/kanata.lisp";
in
{
  options = {
    services.wm = {
      enable = mkEnableOption "wm";
    };
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = lib.mkForce true;
        xkb = {
          variant = "oss";
          options = "eurosign:e,ctrl:swapcaps";
          layout = "fr";
        };
      };
      kanata = {
        enable = true;
        keyboards.all.config = builtins.readFile kanataConfigPath;
        keyboards.all.extraDefCfg = ''
          concurrent-tap-hold yes
        '';
      };
      flatpak.enable = true;
    };

    security.pam.services.gdm.enableGnomeKeyring = true;

    systemd.services.kanata-all.serviceConfig = {
      Restart = "always";
      RestartSec = "1s";
    };

    environment.systemPackages = [
      pkgs.gnome-calculator
      pkgs.gnome-characters
      pkgs.gnome-clocks
      pkgs.gnome-font-viewer
      pkgs.gnome-system-monitor
      pkgs.loupe
      pkgs.gnome-obfuscate
      pkgs.snapshot
      pkgs.nautilus

      #Enable ddc
      pkgs.ddcutil
    ];

    environment.variables = {
      # better fonts:
      # https://web.archive.org/web/20230921201835/https://old.reddit.com/r/linux_gaming/comments/16lwgnj/is_it_possible_to_improve_font_rendering_on_linux/
      FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    };

    services.udev.extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';
    # Load i2c kernel module
    boot.kernelModules = [ "i2c-dev" ];

    users.groups.i2c = { };

    users.users.volodia.extraGroups = [ "i2c" ];
    # Enable sound.
    programs = {
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-tty;
      };
    };

    fonts = {
      packages = [
        pkgs.corefonts
        pkgs.roboto
        pkgs.roboto-serif
        pkgs.joypixels
        pkgs.nerd-fonts.iosevka-term
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-cjk-serif
      ];
      fontconfig.defaultFonts = {
        monospace = [
          "Comic Code Ligatures"
        ];

        sansSerif = [
          "Roboto"
        ];

        serif = [
          "Roboto Serif"
        ];
      };
    };

    nixpkgs.config.joypixels.acceptLicense = true; # Personal use only

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
