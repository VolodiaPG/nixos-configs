{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.laptopServer;
in {
  options = {
    services.laptopServer = with types; {
      enable = mkEnableOption "laptopServer";
    };
  };

  config = mkIf cfg.enable {
    services.logind.lidSwitchExternalPower = "ignore";

    systemd = {
      services.turnOffBacklight = {
        description = "Turn off screen backlight at midnight";
        wantedBy = ["multi-user.target"];
        path = [pkgs.coreutils];
        script = ''
          echo "0" > /sys/class/backlight/intel_backlight/brightness
          echo "1" > /sys/class/graphics/fb0/blank
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      timers.turnOffBacklightTimer = {
        description = "Timer for turning off the screen backlight at midnight";

        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 00:00:00";
          Unit = ["turnOffBacklight.service"];
        };
      };
    };
  };
}
