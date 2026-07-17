{
  config,
  self,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.caddy =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    {
      services.caddy = {
        environmentFile = config.age.secrets.tailscale-authkey.path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"
          ];
          hash = "sha256-XBdYjtuPVu/beIgFgFcVp6ln4r9kq0B6+4xJ8+WWYn0=";
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

        virtualHosts = {
          "http://:80" = {
            extraConfig = ''
              route / {
                  rewrite /index.htm /

                  file_server {
                      index ${
                        pkgs.replaceVars (self + "/static/services-page/index.html") {
                          TAILNAME = me.tailname;
                        }
                      }
                  }
              }

              route * {
                  respond "Not Found" 404
              }
            '';
          };
        };
      };
    };
}
