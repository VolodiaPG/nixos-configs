{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.foldingathome-scheduled;
in {
  options.services.foldingathome-scheduled = {
    enable = mkEnableOption "Scheduled Folding@home client";

    package = mkOption {
      type = types.package;
      default = pkgs.fahclient;
      defaultText = literalExpression "pkgs.fahclient";
      description = "The Folding@home package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "foldingathome";
      description = "User account under which Folding@home runs.";
    };

    group = mkOption {
      type = types.str;
      default = "foldingathome";
      description = "Group account under which Folding@home runs.";
    };

    team = mkOption {
      type = types.str;
      default = "123456";
      description = "Team number to join.";
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      services = {
        foldingathome-scheduled = {
          description = "Folding@home distributed computing client";
          after = ["network.target"];

          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${cfg.package}/bin/fah-client --config-rotate=true";
            Restart = "on-failure";
            RestartSec = "10s";
          };

          # Create a timer that runs only during specified hours on weekdays
          # and all day on weekends
          startLimitIntervalSec = 0;
        };

        foldingathome-scheduled-start = {
          description = "Start Folding@home distributed computing client";
          after = ["network.target"];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl start foldingathome-scheduled";
          };
        };

        foldingathome-scheduled-stop = {
          description = "Stop Folding@home distributed computing client";

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl stop foldingathome-scheduled";
          };
        };
      };

      timers = {
        foldingathome-scheduled-start = {
          description = "Timer for starting Folding@home client";
          wantedBy = ["timers.target"];

          timerConfig = {
            OnCalendar = [
              "Mon-Fri 20:00" # Start at 8 PM on weekdays
              # Doesn't stop for weekends
            ];
            Persistent = true;
          };
        };

        foldingathome-scheduled-stop = {
          description = "Timer for stopping Folding@home client";
          wantedBy = ["timers.target"];

          timerConfig = {
            OnCalendar = [
              "Mon-Fri 06:00" # Stop at 6 AM on weekdays
            ];
            Persistent = true;
          };
        };
      };
    };

    # Create system user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      description = "Folding@home client user";
    };

    users.groups.${cfg.group} = {};
  };
}
