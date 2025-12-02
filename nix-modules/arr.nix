{
  pkgs,
  lib,
  config,
  ...
}:
{
  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    transmission = {
      enable = true; # Enable Transmission for torrents
      peerPort = 50000; # Set peer port
      extraAllowedIps = [ "100.*.*.*" ]; # Allow access from Tailscale
      flood.enable = true;
    };
    bazarr.enable = false; # Enable Bazarr for subtitles
    sonarr.enable = true; # Enable Sonarr for TV shows
    radarr.enable = true; # Enable Radarr for movies
    prowlarr.enable = true; # Enable Prowlarr for indexers
    readarr.enable = false; # Enable Readarr for books
  };

  services.flaresolverr = {
    enable = false;
    port = 8191;
    package = pkgs.flaresolverr;
  };

  # Block transmission user from using non-tailscale interfaces (backup kill switch)
  networking.firewall.extraCommands = ''
    # Get transmission user UID
    TRANSMISSION_UID=$(${config.systemd.package}/bin/systemctl show -p User transmission.service | cut -d= -f2)
    TRANSMISSION_UID=$(id -u "$TRANSMISSION_UID" 2>/dev/null || echo "")
    if [ -n "$TRANSMISSION_UID" ]; then
      # Allow localhost
      iptables -A OUTPUT -m owner --uid-owner "$TRANSMISSION_UID" -o lo -j ACCEPT
      # Block all outgoing traffic from transmission except through tailscale0
      iptables -A OUTPUT -m owner --uid-owner "$TRANSMISSION_UID" ! -o tailscale0 -j REJECT
    fi
  '';

  networking.firewall.extraStopCommands = ''
    TRANSMISSION_UID=$(${config.systemd.package}/bin/systemctl show -p User transmission.service | cut -d= -f2)
    TRANSMISSION_UID=$(id -u "$TRANSMISSION_UID" 2>/dev/null || echo "")
    if [ -n "$TRANSMISSION_UID" ]; then
      iptables -D OUTPUT -m owner --uid-owner "$TRANSMISSION_UID" -o lo -j ACCEPT 2>/dev/null || true
      iptables -D OUTPUT -m owner --uid-owner "$TRANSMISSION_UID" ! -o tailscale0 -j REJECT 2>/dev/null || true
    fi
  '';

  systemd.services = {
    transmission = {
      # Ensure transmission starts after tailscale is up
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [ "tailscaled.service" ];
      bindsTo = [ "tailscaled.service" ]; # Stop transmission if tailscale dies (kill switch)
      serviceConfig = {
        Restart = "always";
        RestartSec = 3;
        # Bind to Tailscale interface only - prevents any traffic on other interfaces
        BindToDevice = "tailscale0";
        # Restrict network access
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
    sonarr.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce 3;
    };
    radarr.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce 3;
    };
    prowlarr.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce 3;
    };
  };

}
