{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.changeMAC;
in {
  options = {
    services.changeMAC = {
      enable = mkEnableOption "changeMAC";
      mac = mkOption {
        description = "MAC address to set";
        type = types.str;
      };
      interface = mkOption {
        description = "The interface to change the mac of";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      services.change-mac = {
        description = "Change MAC Address";
        wantedBy = ["multi-user.target"];
        path = [pkgs.busybox];
        script = ''
          ip link set dev ${cfg.interface} down
          sleep 1
          ifconfig ${cfg.interface} hw ether "${cfg.mac}"
          sleep 1
          ip link set dev ${cfg.interface} up
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
      timers .autoChangeMac = {
        description = "Timer for changing mac automatically";

        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 12:00:00";
          Unit = ["change-mac.service"];
        };
      };
    };
  };
}
