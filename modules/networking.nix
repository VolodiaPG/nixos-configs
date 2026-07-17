_: {
  config.nixos.networking =
    {
      lib,
      ...
    }:
    with lib;
    {
      boot = {
        kernelModules = [ "ip6table_filter" ];
        kernel.sysctl = {
          "net.ipv6.conf.all.disable_ipv6" = 0;
          "net.ipv4.conf.all.forwarding" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
          "net.ipv6.conf.all.accept_ra_rt_info_max_plen" = 64;
          "net.ipv6.conf.all.accept_ra" = 2;
        };
      };
      networking = {
        # useNetworkd = true;
        # useDHCP = false;
        # hostFiles = [
        #   "${inputs.blocklist}/hosts/hosts0"
        #   "${inputs.blocklist}/hosts/hosts1"
        #   "${inputs.blocklist}/hosts/hosts2"
        #   "${inputs.blocklist}/hosts/hosts3"
        #   "${inputs.blocklist}/hosts/hosts4"
        #   "${inputs.blocklist}/hosts/hosts5"
        # ];
        # extraHosts = ''
        #   0.0.0.0 usage-ping.brave.com
        #   0.0.0.0 star-randsrv.bsg.brave.com
        #   0.0.0.0 variations.brave.com
        #   0.0.0.0 collector.bsg.brave.com
        # '';
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
