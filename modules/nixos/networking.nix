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
        "${flake.inputs.blocklist}/hosts/hosts0"
        "${flake.inputs.blocklist}/hosts/hosts1"
        "${flake.inputs.blocklist}/hosts/hosts2"
        "${flake.inputs.blocklist}/hosts/hosts3"
        "${flake.inputs.blocklist}/hosts/hosts4"
        "${flake.inputs.blocklist}/hosts/hosts5"
      ];
      extraHosts = ''
        0.0.0.0 usage-ping.brave.com
        0.0.0.0 star-randsrv.bsg.brave.com
        0.0.0.0 variations.brave.com
        0.0.0.0 collector.bsg.brave.com
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
