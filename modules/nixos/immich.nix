# Extends the *upstream* services.immich: keyed off `services.immich.enable`,
# not an option of its own. Adds the data bind mount, the postgres role and the
# caddy virtual host.
{
  flake,
  config,
  lib,
  ...
}:
let
  inherit (flake.config) me;
  cfg = config.services.immich;
in
{
  config = lib.mkIf cfg.enable {
    services.immich = {
      host = "0.0.0.0";
      port = 2283;
      # openFirewall = false;
      machine-learning.enable = false;
    };

    # Mounting a drive at the default location is easier than trying to figure out what to change everywhere
    systemd.mounts = [
      {
        type = "none"; # Change type to "none" for bind mounts
        what = "/data/immich"; # The actual folder on disk
        where = "/var/lib/immich";
        options = "bind";
        wantedBy = [ "multi-user.target" ];
      }
    ];

    users.users.immich.extraGroups = [
      "postgres"
      "redis-immich"
    ];

    services = {
      postgresql.ensureUsers = [
        {
          name = "immich";
          ensureClauses = {
            login = true;
            superuser = true;
          };
        }
      ];

      caddy = {
        virtualHosts = {
          "https://immich.${me.tailname}" = {
            extraConfig = ''
              bind tailscale/immich

              reverse_proxy http://127.0.0.1:2283 {
                  header_up Host {host}
              }
            '';
          };
        };
      };
    };
  };
}
