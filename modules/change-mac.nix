_: {
  config.nixos.change-mac =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    {
      options.services.changeMAC = with types; {
        mac = mkOption {
          description = "MAC address to set";
          type = path;
        };
        interface = mkOption {
          description = "The interface to change the mac of";
          type = str;
        };
      };

      config = {
        systemd = {
          services.change-mac = {
            description = "Change MAC Address";
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.busybox ];
            script = ''
              while ! [ -f "${config.services.changeMAC.mac}" ] ; do
                sleep 1
              done
              mac=$(head -n 1 "${config.services.changeMAC.mac}")
              ip link set dev ${config.services.changeMAC.interface} down
              sleep 1
              ifconfig ${config.services.changeMAC.interface} hw ether "$mac"
              sleep 1
              ip link set dev ${config.services.changeMAC.interface} up
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              Restart = "on-failure";
              RestartSec = "5s";
            };
          };
          timers.autoChangeMac = {
            description = "Timer for changing mac automatically";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "*-*-* 12:00:00";
              Unit = [ "change-mac.service" ];
            };
          };
        };
      };
    };
}
