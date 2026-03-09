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
            "github.com/tailscale/caddy-tailscale@v0.0.0-20251117033914-662ef34c64b1"
          ];
          hash = "sha256-IJzHTEndpdzPqSMSMF4qf5Y9xqfCWorcN0NrxwpnDZY=";
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
