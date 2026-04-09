{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.networking;
in
{
  options = {
    services.networking = with types; {
      enable = mkEnableOption "networking configuration";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      useDHCP = false;
    };
    systemd.network = {
      enable = true;
      networks = {
        "10-lan" = {
          matchConfig.Name = [
            "enp*"
            "wlp*"
          ];
          networkConfig.DHCP = true;
        };
      };
    };
  };
}
