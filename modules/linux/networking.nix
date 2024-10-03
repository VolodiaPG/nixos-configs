{
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = ["enp*" "wlp*"];
        networkConfig.DHCP = true;
      };
    };
  };
}
