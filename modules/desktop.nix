{
  self,
  ...
}:
{
  config.nixos.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
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
          keyboards.all.config = readFile (self + "/static/kanata.lisp");
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
        ddcutil
      ];

      environment.variables = {
        FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
      };

      services.udev.extraRules = ''
        KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
      '';
      boot.kernelModules = [ "i2c-dev" ];

      users.groups.i2c = { };

      users.users.volodia.extraGroups = [ "i2c" ];

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
          monospace = [ "Comic Code Ligatures" ];
          sansSerif = [ "Roboto" ];
          serif = [ "Roboto Serif" ];
        };
      };

      nixpkgs.config.joypixels.acceptLicense = true;

      networking.firewall = {
        enable = true;
        allowedTCPPortRanges = [
          {
            from = 6881;
            to = 6999;
          }
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedTCPPorts = [
          22
          3389
        ];
        allowedUDPPorts = [
          3389
          5353
        ];
      };
    };
}
