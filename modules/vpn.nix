_: {
  config.nixos.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
      cfg = config.services.vpn;
    in
    {
      options.services.vpn = with types; {
        nameservers = mkOption {
          description = "dns nameservers";
          type = listOf types.str;
          default = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
      };

      config = {
        services.tailscale = {
          enable = true;
          extraUpFlags = [
            "--advertise-tags=tag:server"
            "--advertise-exit-node"
          ];
        };
        networking = {
          inherit (cfg) nameservers;
          firewall = {
            trustedInterfaces = [ "tailscale0" ];
            checkReversePath = "loose";
            allowedUDPPorts = [ 41641 ];
            allowedTCPPorts = [ 22 ];
          };
        };
        environment.systemPackages = [ pkgs.tailscale ];
      };
    };
}
