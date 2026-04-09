{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.blocky;
in
{
  config = mkIf cfg.enable {
    networking = {
      nameservers = [ "127.0.0.1" ];
      networkmanager.dns = "none";
    };

    services.blocky = {
      settings = {
        ports.dns = 53;
        upstreams = {
          groups.default = [
            "https://dns.nextdns.io/aae83d"
            "tcp-tls:dns.nextdns.io:853#aae83d"
          ];
          strategy = "parallel_best";
          timeout = "2s";
        };
        bootstrapDns = {
          upstream = "https://dns.nextdns.io/aae83d";
          ips = [
            "45.90.28.0"
            "45.90.30.0"
          ];
        };
        blocking = {
          blockType = "nxdomain";
          downloadTimeout = "2m";
          downloadAttempts = 3;
          downloadCooldown = "10s";
          refreshPeriod = "24h";
          # whiteLists = {
          #   default = [
          #   ];
          # };
          blackLists = {
            blocklist = [
              "https://blocklistproject.github.io/Lists/abuse.txt"
              "https://blocklistproject.github.io/Lists/crypto.txt"
              "https://blocklistproject.github.io/Lists/drugs.txt"
              "https://blocklistproject.github.io/Lists/fraud.txt"
              "https://blocklistproject.github.io/Lists/gambling.txt"
              "https://blocklistproject.github.io/Lists/malware.txt"
              "https://blocklistproject.github.io/Lists/phishing.txt"
              "https://blocklistproject.github.io/Lists/ransomware.txt"
              "https://blocklistproject.github.io/Lists/redirect.txt"
              "https://blocklistproject.github.io/Lists/scam.txt"
              "https://blocklistproject.github.io/Lists/tracking.txt"
            ];
            steven = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
            ];
            ultimate = [
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts0.deny"
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts1.deny"
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts2.deny"
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts3.deny"
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts4.deny"
              "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/refs/heads/master/superhosts.deny/superhosts5.deny"
            ];
          };
          clientGroupsBlock = {
            default = [
              "blocklist"
              "steven"
              "ultimate"
            ];
          };
        };
        caching = {
          minTime = "15m";
          maxTime = "2h";
          prefetching = true;
          prefetchExpires = "24h";
          prefetchThreshold = 5;
        };
      };
    };
  };
}
