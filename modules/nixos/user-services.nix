{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.user-services;

  tidal-pkg = flake.inputs.tidal-to-strawberry.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options = {
    user-services = {
      gpg-agent = mkEnableOption "gpg-agent with SSH support and pinentry-tty";
      darkman = mkEnableOption "darkman theme switching daemon";
      syncthing = mkEnableOption "syncthing file synchronization";
      kdeconnect = mkEnableOption "KDE Connect";
      niriusd = mkEnableOption "niriusd daemon for niri scratchpad";
      tidal-to-strawberry = mkEnableOption "tidal-to-strawberry sync service";
    };
  };

  config = mkMerge [
    (mkIf cfg.gpg-agent {
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-tty;
      };
    })

    (mkIf cfg.darkman {
      environment.systemPackages = [
        pkgs.darkman
        pkgs.theme-switcher
      ];

      systemd.user.services.darkman = {
        Unit = {
          Description = "Darkman theme switching daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.darkman}/bin/darkman run";
          Restart = "on-failure";
          RestartSec = "3s";
        };
      };
    })

    (mkIf cfg.syncthing {
      environment.systemPackages = [ pkgs.syncthing ];

      systemd.user.services.syncthing = {
        Unit = {
          Description = "Syncthing file synchronization";
          After = [ "network.target" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.syncthing}/bin/syncthing --no-browser --gui-address=0.0.0.0:8384";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    })

    (mkIf cfg.kdeconnect {
      programs.kdeconnect.enable = true;
    })

    (mkIf cfg.niriusd {
      environment.systemPackages = [ pkgs.nirius ];

      systemd.user.services.niriusd = {
        Unit = {
          Description = "Nirius daemon for niri scratchpad functionality";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.nirius}/bin/niriusd";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    })

    (mkIf cfg.tidal-to-strawberry {
      environment.systemPackages = [ tidal-pkg ];

      systemd.user.services.tidal-to-strawberry = {
        Unit = {
          Description = "Tidal to Strawberry sync service";
          After = [ "network.target" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${tidal-pkg}/bin/tidal-to-strawberry";
          WorkingDirectory = "%h/Music";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      systemd.user.timers.tidal-to-strawberry = {
        Unit = {
          Description = "Tidal to Strawberry sync timer";
        };
        Timer = {
          OnCalendar = "*:0/5";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
  ];
}
