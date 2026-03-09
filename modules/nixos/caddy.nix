{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.caddy;
in
{

  config = mkIf cfg.enable {
    services = {
      caddy = {
        environmentFile = config.age.secrets.tailscale-authkey.path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/tailscale/caddy-tailscale@bb080c4"
          ];
          hash = "sha256-9CYQSdGAQwd1cmFuKT2RNzeiJ4DZoyrxvsLS4JDCFCY=";
        };
        globalConfig = ''
          servers {
              protocols h1 h2
          }
        '';
      };
    };
  };
}
