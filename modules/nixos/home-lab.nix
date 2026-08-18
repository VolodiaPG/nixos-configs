{
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.homeLab;
  inherit (flake.config) me;
in
{
  options = {
    services.homeLab = {
      enable = mkEnableOption "home lab services";
    };
  };

  config = mkIf cfg.enable {
    services.my_virtualization.enable = true;
    virtualisation.oci-containers = {
      containers = {
        fizzy = {
          image = "ghcr.io/basecamp/fizzy:main";
          pull = "always";
          ports = [ "8888:80" ];
          environmentFiles = [ config.age.secrets.fizzy-env.path ];
          environment = {
            BASE_URL = "https://fizzy.goblin-alewife.ts.net";
            MAILER_FROM_ADDRESS = "bot.volodia@gmail.com";
            DISABLE_SSL = "true";
            SMTP_ADDRESS = "smtp.gmail.com";
            SMTP_USERNAME = "bot.volodia@gmail.com";
            # Reduce memory fragmentation in Ruby
            MALLOC_ARENA_MAX = "2";
            WEB_CONCURRENCY = "2";
            JOB_CONCURRENCY = "2";
          };
          volumes = [ "/home/${me.username}/Documents/services/fizzy:/rails/storage" ];
        };
      };
    };

    # systemd.services."docker-fizzy" = {
    #   serviceConfig = {
    #     # CPUQuota = "100%";
    #
    #     # Relative CPU weight (cgroups v2 replacement for cpu-shares, 1-10000)
    #     CPUWeight = 50;
    #   };
    # };

    services = {
      caddy = {
        virtualHosts = {
          # "https://hass.${me.tailname}" = {
          #   extraConfig = ''
          #     bind tailscale/hass
          #
          #     reverse_proxy http://127.0.0.1:8123 {
          #         header_up Host {host}
          #     }
          #   '';
          # };
          "https://rss.${me.tailname}" = {
            extraConfig = ''
              bind tailscale/rss

              reverse_proxy http://127.0.0.1:8082 {
                  header_up Host {host}
              }
            '';
          };
          "https://fizzy.${me.tailname}" = {
            extraConfig = ''
              bind tailscale/fizzy

              reverse_proxy http://127.0.0.1:8888 {
                  header_up Host {host}
              }
            '';
          };
        };
      };
    };
  };
}
