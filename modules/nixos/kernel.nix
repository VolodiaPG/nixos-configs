{
  config,
  lib,
  flake,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.services.kernel;
  inherit (flake.inputs) nix-cachyos-kernel;
  cachyos-kernel = nix-cachyos-kernel.packages.${pkgs.system};
in
{
  options = {
    services.kernel = {
      enable = mkEnableOption "kernel configuration";

      cachyDesktop = mkEnableOption "Cachy kernel";
      cachyServer = mkEnableOption "Cachy kernel";

      lowLatencyNetworking = mkEnableOption "low-latency client networking";

      serverNetworking = mkEnableOption "server networking";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.lowLatencyNetworking && cfg.serverNetworking);
        message = "services.kernel.lowLatencyNetworking and services.kernel.serverNetworking are mutually exclusive";
      }
      {
        assertion = !(cfg.cachyDesktop && cfg.cachyServer);
        message = "services.kernel.cachyDesktop and services.kernel.cachyServer are mutually exclusive";
      }
    ];

    boot.kernelPackages = mkMerge [
      (mkIf cfg.cachyDesktop cachyos-kernel.linuxPackages-cachyos-latest-lto-x86_64-v3)
      (mkIf cfg.cachyServer cachyos-kernel.linuxPackages-cachyos-server)
    ];

    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd"; # Fast compression with good ratio
      priority = 100; # Highest priority over disk swap
      memoryPercent = 100;
    };

    boot = {
      kernelModules = mkIf cfg.serverNetworking [ "tcp_bbr" ];
      kernel.sysctl = mkMerge [
        (mkIf cfg.lowLatencyNetworking {
          "net.core.default_qdisc" = "fq_codel";
          "net.ipv4.tcp_congestion_control" = "cubic";
          "vm.swappiness" = 10;
        })
        (mkIf cfg.serverNetworking {
          "net.core.default_qdisc" = "fq";
          "net.ipv4.tcp_congestion_control" = "bbr";
          "net.core.somaxconn" = 8192;
          "net.ipv4.tcp_max_syn_backlog" = 8192;
        })
      ];
    };
  };
}
