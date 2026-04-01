{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.services.wm;
  kanataConfigPath = flake.self + "/static/kanata.lisp";
in
{
  options = {
    services.wm = with types; {
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
        keyboards.all.config = readFile kanataConfigPath;
        keyboards.all.extraDefCfg = ''
          concurrent-tap-hold yes
        '';
      };
    };

    security.pam.services.gdm.enableGnomeKeyring = true;

    systemd.services.kanata-all.serviceConfig = {
      Restart = "always";
      RestartSec = "1s";
    };

    environment.systemPackages = with pkgs; [
      gnome-calculator
      gnome-characters
      gnome-clocks
      gnome-font-viewer
      gnome-system-monitor
      loupe
      gnome-obfuscate
      snapshot
      nautilus

      #Enable ddc
      ddcutil
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
      packages = with pkgs; [
        corefonts
        roboto
        roboto-serif
        joypixels
        nerd-fonts.iosevka-term
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
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
