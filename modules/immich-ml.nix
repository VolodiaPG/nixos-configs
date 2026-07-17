{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.immich-ml =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    {
      options.services.immich-ml.port = mkOption {
        type = types.port;
        default = 3003;
      };

      config = {
        virtualisation.oci-containers = {
          containers.immich-machine-learning = {
            image = "ghcr.io/immich-app/immich-machine-learning:v${pkgs.immich.version}-cuda";
            ports = [ "${toString config.services.immich-ml.port}:3003" ];
            volumes = [ "immich-ml-cache:/cache" ];
            extraOptions = [ "--device=nvidia.com/gpu=all" ];
          };
        };

        services.caddy = {
          virtualHosts = {
            "https://immich-ml.${me.tailname}" = {
              extraConfig = ''
                bind tailscale/immich-ml
                reverse_proxy http://127.0.0.1:3003 {
                    header_up Host {host}
                }
              '';
            };
          };
        };
      };
    };
}
