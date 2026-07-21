{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  inherit (lib) mkIf mkOption;
  inherit (flake) inputs;
  cfg = config.services.kernel;
in
{
  options = {
    services.kernel = {
      enable = mkOption {
        description = "Enable the configuration of the kernel";
        type = lib.types.bool;
        default = false;
      };

      maxPower = mkOption {
        description = "Enable the usage maxium power";
        type = lib.types.bool;
        default = false;
      };

      latestKernel = mkOption {
        description = "Use the latest kernel";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  imports = [ inputs.bbr_classic.nixosModules.default ];

  config = mkIf cfg.enable {
    networking.bbr_classic = {
      enable = true;

      # Automatically sets the following sysctls:
      # net.ipv4.tcp_congestion_control = "bbr_classic"
      # net.core.default_qdisc = "fq"
      setAsDefault = true;
    };

    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    boot = {
      # kernelModules = [
      #   "ecryptfs"
      # ];
      kernelPackages = lib.mkIf cfg.latestKernel (lib.mkForce pkgs.linuxPackages_latest);
    };

    services = {
      # power-profiles-daemon.enable = false;
      thermald.enable = pkgs.stdenv.isx86_64;
      acpid.enable = true;
      # tlp = {
      #   enable = false;
      #   settings = {
      #     CPU_BOOST_ON_BAT = 0;
      #     CPU_BOOST_ON_AC = 1;
      #     CPU_HWP_DYN_BOOST_ON_AC = 1;
      #     CPU_HWP_DYN_BOOST_ON_BAT = 0;
      #     CPU_SCALING_GOVERNOR_ON_BATTERY = "conservative";
      #     CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      #     PLATFORM_PROFILE_ON_AC = "performance";
      #     PLATFORM_PROFILE_ON_BAT = "low-power";
      #     AMDGPU_ABM_LEVEL_ON_AC = 0;
      #     AMDGPU_ABM_LEVEL_ON_BAT = 3;
      #     WIFI_PWR_ON_AC = "off";
      #     WIFI_PWR_ON_BAT = "on";
      #     RUNTIME_PM_ON_BAT = "auto";
      #     WOL_DISABLE = "Y";
      #     MEM_SLEEP_ON_BAT = "deep";
      #   };
      # };
    };

    # ============================================================================
    # ZRAM SWAP CONFIGURATION
    # ============================================================================
    # ZRAM provides compressed swap in RAM, which is faster than disk swap.
    # Higher priority (100) ensures zram is used before any disk swap.
    # 200% memoryPercent allows aggressive compression for RAM extension.
    zramSwap = {
      enable = true;
      algorithm = "zstd"; # Fast compression with good ratio
      priority = 100; # Highest priority over disk swap
      memoryPercent = 200; # Use up to 4x RAM size for compressed swap
      # memoryPercent = 300; # Use up to 4x RAM size for compressed swap
    };

    boot.kernel.sysctl = {
      # 2. Transmit Buffer Queue Cap (Most Important for Latency)
      "net.ipv4.tcp_notsent_lowat" = 16384;

      # 3. Connection Setup & Idle Latency Reduction
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;

      # 4. Socket Buffer Limits (Prevents Bufferbloat)
      "net.core.rmem_max" = 8388608;
      "net.core.wmem_max" = 8388608;
      "net.ipv4.tcp_rmem" = "4096 87380 8388608";
      "net.ipv4.tcp_wmem" = "4096 65536 8388608";

      # 5. Immediate Packet Dispatch
      "net.ipv4.tcp_autocorking" = 0;
    };
  };
}
