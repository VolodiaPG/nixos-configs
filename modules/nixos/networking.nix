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
  options = {
    services.networking = with types; {
      enable = mkEnableOption "networking configuration";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      # useNetworkd = true;
      # useDHCP = false;
      hostFiles = [
        "${flake.inputs.blocklist}/superhosts.deny/superhosts0.deny"
        "${flake.inputs.blocklist}/superhosts.deny/superhosts1.deny"
        "${flake.inputs.blocklist}/superhosts.deny/superhosts2.deny"
        "${flake.inputs.blocklist}/superhosts.deny/superhosts3.deny"
        "${flake.inputs.blocklist}/superhosts.deny/superhosts4.deny"
        "${flake.inputs.blocklist}/superhosts.deny/superhosts5.deny"
      ];
      extraHosts = ''
        ALL: usage-ping.brave.com
        ALL: star-randsrv.bsg.brave.com
        ALL: variations.brave.com
        ALL: collector.bsg.brave.com
      '';
    };
    # systemd.network = {
    #   enable = true;
    #   networks = {
    #     "10-lan" = {
    #       matchConfig.Name = [
    #         "enp*"
    #         "wlp*"
    #       ];
    #       networkConfig.DHCP = true;
    #     };
    #   };
    # };
  };
}
