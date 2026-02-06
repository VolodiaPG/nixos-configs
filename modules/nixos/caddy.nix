{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.myCaddy;
in
{
  options = {
    services.myCaddy = with types; {
      enable = mkEnableOption "Caddy web server";
    };
  };

  config = mkIf cfg.enable {
    services = {
      caddy = {
        enable = true;
        environmentFile = config.age.secrets.tailscale-authkey.path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/tailscale/caddy-tailscale@v0.0.0-20251117033914-662ef34c64b1"
          ];
          hash = "sha256-LZPejlDq/ak5w/h9V3ic8XFpj4QU4ce/3dLA1w8RAD0=";
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
