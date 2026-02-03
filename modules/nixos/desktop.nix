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
    services = {
      xserver = {
        enable = lib.mkForce true;
        xkb = {
          variant = "oss";
          options = "eurosign:e,ctrl:swapcaps";
          layout = "fr";
        };
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

      udev.packages = [ pkgs.gnome-settings-daemon ];

      gnome.core-apps.enable = false;

      kanata = {
        enable = true;
        keyboards.all.config = readFile ./kanata.lisp;
        keyboards.all.extraDefCfg = ''
          concurrent-tap-hold yes
        '';
      };
    };

    environment.systemPackages = [
      pkgs.gnome-calculator
      pkgs.gnome-characters
      pkgs.gnome-clocks
      pkgs.gnome-font-viewer
      pkgs.gnome-system-monitor
      pkgs.gnome-weather
      pkgs.loupe
      pkgs.nautilus
      pkgs.snapshot

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
      dconf.enable = true;
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
        joypixels
        nerd-fonts.iosevka-term
      ];
      fontconfig.defaultFonts = {
        monospace = [
          "Comic Code Ligatures"
        ];

        sansSerif = [
          "Roboto"
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
