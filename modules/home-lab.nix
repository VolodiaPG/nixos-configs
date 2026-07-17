{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.homeLab =
    {
      lib,
      config,
      ...
    }:
    with lib;
    {
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
            };
            volumes = [ "/home/${me.username}/Documents/services/fizzy:/rails/storage" ];
          };
        };
      };

      services.caddy = {
        virtualHosts = {
          "https://hass.${me.tailname}" = {
            extraConfig = ''
              bind tailscale/hass
              reverse_proxy http://127.0.0.1:8123 {
                  header_up Host {host}
              }
            '';
          };
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
}
