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
            "github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"
          ];
          hash = "sha256-V48tcZ8oCqXVz+1kWrsc59yESNSevg4j2vJN34KQ+tQ=";
        };
        globalConfig = ''
          servers {
              protocols h1 h2
          }
          tailscale {
            ephemeral
            tags tag:homelab
          }
        '';
      };
    };
  };
}
