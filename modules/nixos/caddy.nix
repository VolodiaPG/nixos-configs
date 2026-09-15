{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.services.caddy;
in
{

  config = mkIf cfg.enable {
    services = {
      caddy = {
        environmentFile = config.age.secrets.tailscale-authkey.path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/tailscale/caddy-tailscale@v0.0.0-20260826180304-de41b249af4f"
          ];
          hash = "sha256-IzLM8Qgxurrgs6NBygGEGyzXQUxQMPP3Y6iIWVN5ZvQ=";
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

        # virtualHosts = {
        #   "http://:80" = {
        #     extraConfig = ''
        #       # Route for the root request (and redirect if needed, like /index.htm -> /)
        #       route / {
        #           rewrite /index.htm /
        #
        #           file_server {
        #               index ${
        #                 pkgs.replaceVars (self + "/static/services-page/index.html") {
        #                   TAILNAME = me.tailname;
        #                 }
        #               }
        #           }
        #       }
        #
        #       route * {
        #           respond "Not Found" 404
        #       }
        #     '';
        #   };
        # };
      };
    };
  };
}
