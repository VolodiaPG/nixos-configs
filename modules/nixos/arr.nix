{
  pkgs,
  lib,
  config,
  user,
  ...
}:
# let
#   # Helper function to create scheduled stop/start service pairs
#   mkScheduledService = serviceName: {
#     services = {
#       "${serviceName}-stop" = {
#         description = "Stop ${serviceName} service";
#         serviceConfig = {
#           Type = "oneshot";
#           ExecStart = "${pkgs.systemd}/bin/systemctl stop ${serviceName}.service";
#         };
#       };
#       "${serviceName}-start" = {
#         description = "Start ${serviceName} service";
#         serviceConfig = {
#           Type = "oneshot";
#           ExecStart = "${pkgs.systemd}/bin/systemctl start ${serviceName}.service";
#         };
#       };
#     };
#     timers = {
#       "${serviceName}-stop" = {
#         description = "Stop ${serviceName} at 22:30";
#         timerConfig = {
#           OnCalendar = "*-*-* 22:30:00";
#           Persistent = true;
#         };
#         wantedBy = [ "timers.target" ];
#       };
#       "${serviceName}-start" = {
#         description = "Start ${serviceName} at 07:30";
#         timerConfig = {
#           OnCalendar = "*-*-* 07:30:00";
#           Persistent = true;
#         };
#         wantedBy = [ "timers.target" ];
#       };
#     };
#   };

# Generate scheduled services for each service
# scheduledServices =
#   lib.foldr (serviceName: acc: lib.recursiveUpdate acc (mkScheduledService serviceName))
#     {
#       services = { };
#       timers = { };
#     }
#     [
#       "transmission"
#       "sonarr"
#       "radarr"
#       "prowlarr"
#     ];
# in
{
  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    transmission = {
      enable = true; # Enable Transmission for torrents
      peerPort = 50000; # Set peer port
      extraAllowedIps = [
        "100.*"
      ]; # Allow access from Tailscale
      flood.enable = true;
    };
    bazarr.enable = false; # Enable Bazarr for subtitles
    sonarr.enable = true; # Enable Sonarr for TV shows
    radarr.enable = true; # Enable Radarr for movies
    prowlarr.enable = true; # Enable Prowlarr for indexers
    jellyfin.enable = false; # Enable Jellyfin for media
  };

  services.transmission.settings = {
    rpc-host-whitelist-enabled = false;
    rpc-whitelist-enabled = lib.mkForce false;
    rpc-bind-address = lib.mkForce "127.0.0.1";
  };

  # services.flaresolverr = {
  #   enable = false;
  #   port = 8191;
  #   package = pkgs.flaresolverr;
  # };

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

  systemd = {
    services = {
      transmission = {
        # Ensure transmission starts after tailscale is up
        after = [
          "tailscaled.service"
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
    # // scheduledServices.services;

    # inherit (scheduledServices) timers;
  };

  services.caddy = {
    virtualHosts = {
      "http://:80" = {
        extraConfig = ''
          # Route for the root request (and redirect if needed, like /index.htm -> /)
          route / {
              rewrite /index.htm /

              file_server {
                  index ${
                    pkgs.replaceVars ./services-page/index.html {
                      TAILNAME = user.tailname;
                    }
                  }
              }
          }

          route * {
              respond "Not Found" 404
          }
        '';
      };

      "https://hass.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/hass

          reverse_proxy http://127.0.0.1:8123 {
              header_up Host {host}
          }
        '';
      };
      "https://rss.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/rss

          reverse_proxy http://127.0.0.1:8082 {
              header_up Host {host}
          }
        '';
      };
      "https://transmission.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/transmission
          reverse_proxy http://127.0.0.1:9091 {
              header_up Host {host}
          }
        '';
      };
      "https://sonarr.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/sonarr
          reverse_proxy http://127.0.0.1:8989 {
              header_up Host {host}
          }
        '';
      };
      "https://radarr.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/radarr
          reverse_proxy http://127.0.0.1:7878 {
              header_up Host {host}
          }
        '';
      };
      "https://prowlarr.${user.tailname}" = {
        extraConfig = ''
          bind tailscale/prowlarr
          reverse_proxy http://127.0.0.1:9696 {
              header_up Host {host}
          }
        '';
      };
    };
  };
}
