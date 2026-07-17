_: {
  config.nixos.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
      cfg = config.services.kernel;
    in
    {
      options.services.kernel = with types; {
        maxPower = mkOption {
          description = "Enable the usage maxium power";
          type = types.bool;
          default = false;
        };

        latestKernel = mkOption {
          description = "Use the latest kernel";
          type = types.bool;
          default = false;
        };
      };

      config = {
        powerManagement = {
          enable = true;
          powertop.enable = true;
        };

        boot = {
          kernelPackages = lib.mkIf cfg.latestKernel (lib.mkForce pkgs.linuxPackages_latest);
        };

        services = {
          thermald.enable = pkgs.stdenv.isx86_64;
          acpid.enable = true;
        };

        zramSwap = {
          enable = true;
          algorithm = "zstd";
          priority = 100;
          memoryPercent = 200;
        };

        boot.kernel.sysctl = {
          "net.core.default_qdisc" = "fq";
          "net.ipv4.tcp_congestion_control" = "bbr";
        };
      };
    };
}
