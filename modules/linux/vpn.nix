{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.vpn;
in {
  options = {
    services.vpn = with types; {
      enable = mkEnableOption "vpn";

      nameservers = mkOption {
        description = "dns nameservers";
        type = listOf types.str;
        default = ["1.1.1.1" "1.0.0.1"];
      };
    };
  };

  config = mkIf cfg.enable {
    # enable the tailscale daemon; this will do a variety of tasks:
    # 1. create the TUN network device
    # 2. setup some IP routes to route through the TUN
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:server"
        "--advertise-exit-node"
        "--accept-dns=false"
      ];
    };
    networking = {
      inherit (cfg) nameservers;
      firewall = {
        trustedInterfaces = ["tailscale0"];
        checkReversePath = "loose";
        # Let's open the UDP port with which the network is tunneled through
        allowedUDPPorts = [41641];
        allowedTCPPorts = [22];
      };
    };

    # Disable SSH access through the firewall
    # Only way into the machine will be through
    # This may cause a chicken & egg problem since you need to register a machine
    # first using `tailscale up`
    # Better to rely on EC2 SecurityGroups
    # services.openssh.openFirewall = false;

    # trace: warning: Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups. Consider setting `networking.firewall.checkReversePath` = 'loose'

    # Let's make the tailscale binary available to all users
    environment.systemPackages = [pkgs.tailscale];
  };
}
