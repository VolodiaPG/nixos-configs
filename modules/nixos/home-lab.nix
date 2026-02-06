{
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  cfg = config.services.homeLab;
  inherit (flake.config) me;
in
{
  options = {
    services.homeLab = with types; {
      enable = mkEnableOption "home lab services";
    };
  };

  config = mkIf cfg.enable {
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
      caddy = {
        virtualHosts = {
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
