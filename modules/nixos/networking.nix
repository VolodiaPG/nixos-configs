{
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.services.networking;
in
{
  imports = [
    flake.inputs.hosts.nixosModule
  ];

  options = {
    services.networking = with types; {
      enable = mkEnableOption "networking configuration";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      stevenBlackHosts = {
        enable = true;
        blockFakenews = true;
        blockGambling = true;
      };
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
