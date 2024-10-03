{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.microvms;
in {
  options = {
    services.microvms = with types; {
      enable = mkEnableOption "microvms";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.trustedInterfaces = ["vbr0"];

    #networking.firewall.allowedUDPPorts = [67];
    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = ["vbr0"];
        externalInterface = "enp3s0";
      };
    };
    systemd.network = {
      netdevs = {
        "10-microvm".netdevConfig = {
          Kind = "bridge";
          Name = "vbr0";
        };
      };
      networks = {
        "10-microvm" = {
          matchConfig.Name = "vbr0";
          networkConfig = {
            DHCPServer = true;
            IPv6SendRA = true;
          };
          addresses = [
            {
              addressConfig.Address = "10.0.0.1/24";
            }
            {
              addressConfig.Address = "fd12:3456:789a::1/64";
            }
          ];
          ipv6Prefixes = [
            {
              ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
            }
          ];
        };
        "11-microvm" = {
          matchConfig.Name = "vm-*";
          networkConfig.Bridge = "vbr0";
        };
      };
    };
  };
}
