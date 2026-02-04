{
  flake,
  config,
  ...
}:
{
  inherit (flake.config) me;
  virtualisation.oci-containers = {
    backend = "docker";
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
        };
        volumes = [ "/home/${me.username}/Documents/Sync/services/fizzy:/rails/storage" ];
      };
    };
  };

  services = {
    #   freshrss = {
    #     enable = true;
    #     dataDir = "/persistent/home-lab/freshrss";
    #     virtualHost = "https://rss.${me.tailname}";
    #     baseUrl = "https://rss.${me.tailname}";
    #     # passwordFile = config.age.secrets.rss-password.path;
    #     authType = "http_auth";
    #     webserver = "caddy";
    #   };
    #   tsidp = {
    #     enable = true;
    #     environmentFile = config.age.secrets.tailscale-authkey.path;
    #   };

    #   #https://msfjarvis.dev/posts/creating-private-services-on-nixos-using-tailscale-and-caddy/
    caddy = {
      virtualHosts = {
        "https://fizzy.${me.tailname}" = {
          extraConfig = ''
            bind tailscale/fizzy
            reverse_proxy http://127.0.0.1:8888 {
                header_up Host {host}
            }

            # tailscale_auth
          '';
        };
      };
    };
  };
}
