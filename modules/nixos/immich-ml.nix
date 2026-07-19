{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (flake.config) me;
  cfg = config.services.immich-ml;
in
{

  options = {
    services.immich-ml = {
      enable = lib.mkEnableOption "immich machine learning remote service";

      port = lib.mkOption {
        type = lib.types.port;
        default = 3003;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Upstream CUDA-enabled ML image, pinned to the same version as the
    # server package so client/server protocol stays in sync.
    virtualisation.oci-containers = {
      containers.immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v${pkgs.immich.version}-cuda";
        ports = [ "${toString cfg.port}:3003" ];
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
}
