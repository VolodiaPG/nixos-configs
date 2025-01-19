{inputs, ...}: {
  imports = [
    inputs.hosts.nixosModule
  ];
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
        matchConfig.Name = ["enp*" "wlp*"];
        networkConfig.DHCP = true;
      };
    };
  };
}
