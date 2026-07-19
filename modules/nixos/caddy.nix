{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.services.caddy;
  inherit (flake.inputs) self;
  inherit (flake.config) me;
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
          hash = "sha256-vC/nyCKMD2jKgbGVA5NIJP6dGXiP9z0yEA8WINgFcVc=";
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
              # Route for the root request (and redirect if needed, like /index.htm -> /)
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
  };
}
