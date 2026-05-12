{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.immich-ml;
in
{

  options = with lib; {
    services.immich-ml = {
      enable = lib.mkEnableOption "immich machine learning remote service";

      port = mkOption {
        type = types.port;
        default = 3003;
      };

      host = mkOption {
        type = types.str;
        default = "[::]";
      };

      workers = mkOption {
        type = types.ints.positive;
        default = 1;
      };

      workerTimeout = mkOption {
        type = types.ints.positive;
        default = 120;
      };

      cuda.enable = mkOption {
        type = types.bool;
        default = pkgs.config.cudaSupport;
        description = "Enable CUDA for the Immich ML service";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.sockets.immich-ml = {
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "0.0.0.0:${toString cfg.port}" ];
      socketConfig.Accept = false;
    };

    systemd.services.immich-ml = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        IMMICH_HOST = cfg.host;
        IMMICH_PORT = toString cfg.port;
        MACHINE_LEARNING_CACHE_FOLDER = "/var/cache/immich-ml";
        IMMICH_MACHINE_LEARNING_WORKERS = toString cfg.workers;
        IMMICH_MACHINE_LEARNING_WORKER_TIMEOUT = toString cfg.workerTimeout;
        MPLCONFIGDIR = "/var/lib/immich-ml";
      };
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.immich-machine-learning}";
        PrivateDevices = !cfg.cuda.enable;
        DeviceAllow = lib.optionals cfg.cuda.enable [
          "/dev/nvidia0"
          "/dev/nvidiactl"
          "/dev/nvidia-uvm"
        ];
        StateDirectory = "immich-ml";
        CacheDirectory = "immich-ml";

        # Hardening
        DynamicUser = true;
        PrivateMounts = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictRealtime = true;
        UMask = "0077";
      };
    };
  };
}
