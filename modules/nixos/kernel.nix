{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.kernel;
  scheds = types.enum [
    "scx_bpfland"
    "scx_central"
    "scx_flash"
    "scx_lavd"
    "scx_layered"
    "scx_nest"
    "scx_p2dq"
    "scx_rlfifo"
    "scx_rustland"
    "scx_rusty"
    "scx_sdt"
    "scx_simple"
    "scx_tickless"
    "scx_userland"
    "scx_cosmos"
  ];
in
{
  options = {
    services.kernel = with types; {
      enable = mkEnableOption "kernel";

      kernel = mkOption {
        description = "enable the use of chosen kernel and params";
        type = types.bool;
        default = false;
      };

      maxPower = mkOption {
        description = "Enable the usage maxium power";
        type = types.bool;
        default = false;
      };

      scx = {
        enable = mkOption {
          description = "Enable the usage of scx";
          type = types.bool;
          default = false;
        };

        battery = {
          scheduler = mkOption {
            description = "scx scheduler to use on battery power";
            type = scheds;
            default = "scx_cosmos";
          };

          args = mkOption {
            description = "Command line arguments for the battery scheduler";
            type = types.str;
            default = "-a -d -p 5000 --flat-idle-scan --preferred-idle-scan";
          };

          extraArgs = mkOption {
            description = "Extra arguments for the battery scheduler";
            type = types.str;
            default = "-m powersave ";
          };

          governor = mkOption {
            description = "CPU governor to use for the battery scheduler";
            type = types.str;
            default = "conservative";
          };
        };

        ac = {
          scheduler = mkOption {
            description = "scx scheduler to use on AC power";
            type = scheds;
            default = "scx_cosmos";
          };

          args = mkOption {
            description = "Command line arguments for the AC scheduler";
            type = types.str;
            default = "-a -s 20000 -d -c 0 -p 0 --flat-idle-scan --preferred-idle-scan";
          };

          extraArgs = mkOption {
            description = "Extra arguments for the AC scheduler";
            type = types.str;
            default = "-m turbo";
          };

          governor = mkOption {
            description = "CPU governor to use for the AC scheduler";
            type = types.str;
            default = "performance";
          };
        };
      };
    };
  };

  config =
    (mkIf (cfg.enable && cfg.latestKernel) {
      boot = {
        kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
      };
    })
    // (mkIf cfg.enable {
      powerManagement = {
        enable = true;
        powertop.enable = true;
      };

      boot = {
        kernelModules = [
          "ecryptfs"
        ];
      };

      services = {
        power-profiles-daemon.enable = false;
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
        memoryPercent = 200; # Use up to 2x RAM size for compressed swap
      };

      boot = {
        # ============================================================================
        # KERNEL PARAMETERS
        # ============================================================================
        # These parameters are applied at boot time and affect kernel behavior globally.
        # Many disable security mitigations for performance - use with caution.
        kernelParams = [
          # ----------------------------------------------------------------------------
          # FILESYSTEM SUPPORT
          # ----------------------------------------------------------------------------
          "ecryptfs" # Enable eCryptfs filesystem support

          # ----------------------------------------------------------------------------
          # SECURITY MITIGATIONS - DISABLED FOR PERFORMANCE
          # ----------------------------------------------------------------------------
          # WARNING: These disable security protections against CPU vulnerabilities.
          # Only use on trusted systems where maximum performance is required.
          "noibrs" # Disable Indirect Branch Restricted Speculation
          "noibpb" # Disable Indirect Branch Prediction Barrier
          "nopti" # Disable Page Table Isolation (Meltdown protection)
          "nospectre_v2" # Disable Spectre variant 2 protections
          "nospectre_v1" # Disable Spectre variant 1 protections
          "l1tf=off" # Disable L1 Terminal Fault mitigations
          "nospec_store_bypass_disable" # Disable Speculative Store Bypass protection
          "no_stf_barrier" # Disable Store-to-Load forwarding barrier
          "mds=off" # Disable Microarchitectural Data Sampling mitigations
          "tsx_async_abort=off" # Disable TSX Async Abort mitigations
          "mitigations=off" # Disable all CPU vulnerability mitigations
          "tsx=on" # Enable Intel TSX (Transactional Synchronization Extensions)

          # Additional security mitigations disabled for performance
          "split_lock_detect=off" # Disable split-lock detection (prevents performance hits)
          "l1d_flush=off" # Disable L1 data cache flush on context switch
          "mmio_stale_data=off" # Disable MMIO stale data mitigations
          "retbleed=off" # Disable Retbleed mitigations (return stack buffer)
          "spectre_bhi=off" # Disable Spectre BHB (Branch History Injection) mitigations
          "gather_data_sampling=off" # Disable GDS (Gather Data Sampling) mitigations
          "reg_file_data_sampling=off" # Disable RFDS mitigations

          # ----------------------------------------------------------------------------
          # LOW LATENCY - TIMER AND SCHEDULING
          # ----------------------------------------------------------------------------
          # These settings minimize scheduling latency for real-time audio/gaming
          "preempt=full" # Full kernel preemption for lowest latency
          "threadirqs" # Run IRQ handlers in threads (allows priority)
          "hrtimer" # High-resolution timer support
          "skew_tick=1" # Offset timer interrupts across CPUs (reduce contention)
          "timer_migration=0" # Keep timers on their original CPU (reduce latency)
          "nohz=on" # Enable tickless kernel
          "nohz_full=all" # Disable timer tick on all CPUs when idle (tickless)
          "rcu_nocbs=all" # Offload RCU callbacks to prevent latency spikes
          "rcutree.enable_rcu_lazy=1" # Enable lazy RCU to batch callbacks

          # ----------------------------------------------------------------------------
          # LOW LATENCY - CPU IDLE AND POWER STATES
          # ----------------------------------------------------------------------------
          # These minimize wake latency but increase power consumption
          # "processor.max_cstate=1"  # Limit CPU to shallowest idle state (C1)
          (mkIf cfg.maxPower "idle=poll") # Use polling idle instead of sleep (lowest latency)
          (mkIf cfg.maxPower "intel_pstate=passive") # Use passive mode for Intel P-State driver
          (mkIf cfg.maxPower "amd_pstate=passive") # Use passive mode for AMD P-State driver

          # ----------------------------------------------------------------------------
          # CPU FEATURES - AVX-512
          # ----------------------------------------------------------------------------
          # Disable AVX-512 if it causes CPU downclocking on Intel processors
          "clearcpuid=514" # Clear CPUID bit 514 (AVX-512F)

          # ----------------------------------------------------------------------------
          # I/O PERFORMANCE
          # ----------------------------------------------------------------------------
          (mkIf cfg.maxPower "pci=pcie_bus_perf") # Optimize PCIe for performance over power saving
          "nvme.poll_queues=8" # Increase NVMe polling queues for I/O throughput
          "scsi_mod.use_blk_mq=1" # Use multi-queue block layer for SCSI
          "dm_mod.use_blk_mq=1" # Use multi-queue block layer for device mapper

          # ----------------------------------------------------------------------------
          # USB POWER MANAGEMENT
          # ----------------------------------------------------------------------------
          "usbcore.autosuspend=-1" # Disable USB autosuspend (prevent device delays)

          # ----------------------------------------------------------------------------
          # BOOT MESSAGES - REDUCE VERBOSITY
          # ----------------------------------------------------------------------------
          "rd.udev.log_level=3" # Reduce initrd udev log verbosity
          "udev.log_priority=3" # Reduce udev log verbosity
          "quiet" # Suppress kernel boot messages
          "loglevel=3" # Set console log level (errors only)
        ];

        # ============================================================================
        # KERNEL SYSCTL SETTINGS
        # ============================================================================
        # These are runtime kernel parameters adjusted via /proc/sys
        kernel.sysctl = {

          # --------------------------------------------------------------------------
          # VM DIRTY RATIOS - WRITE-BACK BEHAVIOR
          # --------------------------------------------------------------------------
          # Lower values reduce memory pressure but increase disk writes.
          # These settings prioritize low latency for audio/real-time workloads.
          "vm.dirty_background_ratio" = 1; # Start background flush at 1% dirty pages
          "vm.dirty_ratio" = 3; # Start blocking writes at 3% dirty pages
          "vm.dirty_background_bytes" = 4194304; # 4MB background threshold
          "vm.dirty_bytes" = 12582912; # 12MB blocking threshold
          "vm.dirty_expire_centisecs" = 500; # Data expires after 5 seconds
          "vm.dirty_writeback_centisecs" = 100; # Writeback thread wakes every 1 second

          # --------------------------------------------------------------------------
          # REAL-TIME SCHEDULING
          # --------------------------------------------------------------------------
          # Allow unlimited runtime for real-time tasks (critical for audio/gaming)
          "kernel.sched_rt_runtime_us" = -1; # No limit on RT task runtime
          "kernel.sched_rt_period_us" = 1000000; # 1 second RT accounting period

          # --------------------------------------------------------------------------
          # CFS SCHEDULER TUNING - LOW LATENCY
          # --------------------------------------------------------------------------
          # These control Completely Fair Scheduler latency targets
          # "kernel.sched_latency_ns" = 1000000; # Target 1ms scheduling latency
          # "kernel.sched_min_granularity_ns" = 100000; # Minimum task time slice: 100us
          # "kernel.sched_wakeup_granularity_ns" = 50000; # Wakeup preemption granularity: 50us
          # "kernel.sched_migration_cost_ns" = 500000; # Cost of migrating tasks: 500us
          # "kernel.sched_nr_fork_threshold" = 2; # Fork threshold for load balancing
          # "kernel.sched_cfs_bandwidth_slice_us" = 500; # CFS bandwidth slice: 500us

          # --------------------------------------------------------------------------
          # SWAP BEHAVIOR
          # --------------------------------------------------------------------------
          # Low swappiness keeps pages in RAM, improving responsiveness
          "vm.swappiness" = 10; # Strong preference for keeping data in RAM

          # --------------------------------------------------------------------------
          # WATERMARK SETTINGS (from NixOS PR #268121)
          # --------------------------------------------------------------------------
          # These control when kswapd wakes up and how aggressive it is
          "vm.watermark_boost_factor" = 0; # Disable watermark boosting
          "vm.watermark_scale_factor" = 125; # Scale watermark by 0.5% (default: 10 = 0.04%)
          "vm.page-cluster" = 0; # Disable swap readahead (zram optimization)

          # --------------------------------------------------------------------------
          # MEMORY PERFORMANCE
          # --------------------------------------------------------------------------
          # VFS cache pressure - lower value keeps directory/inode cache longer
          "vm.vfs_cache_pressure" = 50; # Less aggressive reclaim of VFS cache

          # VM statistics update interval (reduce overhead)
          "vm.stat_interval" = 10; # Update VM stats every 10 seconds

          # Memory compaction settings
          "vm.compact_unevictable_allowed" = 1; # Allow compacting unevictable pages
          "vm.compaction_proactiveness" = 0; # Disable proactive compaction
          "vm.extfrag_threshold" = 100; # Fragmentation threshold

          # Minimum free memory and mappings
          "vm.min_free_kbytes" = 65536; # Minimum 64MB free memory
          "vm.max_map_count" = 524288; # Max memory map areas (for large apps)
          # "vm.percpu_pagelist_fraction" = 0; # Disable per-CPU page list draining

          # # --------------------------------------------------------------------------
          # # WATCHDOG TIMERS - DISABLED FOR PERFORMANCE
          # # --------------------------------------------------------------------------
          # # Disable watchdogs to reduce overhead and improve latency consistency
          # "kernel.nmi_watchdog" = 0; # Disable NMI watchdog
          # "kernel.soft_watchdog" = 0; # Disable soft lockup watchdog
          # "kernel.watchdog" = 0; # Disable hardware watchdog
          # "kernel.watchdog_thresh" = 0; # Disable watchdog threshold

          # --------------------------------------------------------------------------
          # OUT-OF-MEMORY BEHAVIOR
          # --------------------------------------------------------------------------
          # Kill the task causing OOM rather than scanning for best candidate
          "vm.oom_kill_allocating_task" = 1;

          # --------------------------------------------------------------------------
          # KERNEL SECURITY (REDUCED FOR PERFORMANCE)
          # --------------------------------------------------------------------------
          # WARNING: These reduce security - only use on trusted systems
          "kernel.randomize_va_space" = 0; # Disable ASLR (Address Space Layout Randomization)

          # Keyring limits (increased for high-connection workloads)
          "kernel.keys.maxkeys" = 2000;
          "kernel.keys.maxbytes" = 2000000;

          # Process/thread limits (increased for high-concurrency workloads)
          "kernel.pid_max" = 4194304; # Maximum PID value
          "kernel.threads-max" = 4194304; # Maximum number of threads

          # Disable kexec (prevents loading another kernel from running system)
          "kernel.kexec_load_disabled" = 1;

          # --------------------------------------------------------------------------
          # FILESYSTEM LIMITS
          # --------------------------------------------------------------------------
          # Maximum number of open files
          "fs.file-max" = 2097152;

          # Inotify limits (for file watching applications)
          "fs.inotify.max_user_watches" = 524288; # Max watches per user
          "fs.inotify.max_user_instances" = 8192; # Max inotify instances per user

          # Asynchronous I/O limits
          "fs.aio-max-nr" = 1048576; # Max number of async I/O requests

          # --------------------------------------------------------------------------
          # NUMA (NON-UNIFORM MEMORY ACCESS)
          # --------------------------------------------------------------------------
          # Disable automatic NUMA balancing (reduces overhead on non-NUMA systems)
          "kernel.numa_balancing" = 0;

          # --------------------------------------------------------------------------
          # NETWORK - CONGESTION CONTROL AND QUEUEING
          # --------------------------------------------------------------------------
          # CAKE (Common Applications Kept Enhanced) - fair queueing with low latency
          "net.core.default_qdisc" = "cake";

          # BBR (Bottleneck Bandwidth and RTT) - Google's congestion control algorithm
          # Provides higher throughput and lower latency than CUBIC
          "net.ipv4.tcp_congestion_control" = "bbr";

          # --------------------------------------------------------------------------
          # NETWORK - TCP CONNECTION HANDLING
          # --------------------------------------------------------------------------
          # TCP Fast Open - allow data in SYN packet (reduces 1-RTT)
          "net.ipv4.tcp_fastopen" = 3; # Enable for both client and server

          # TIME-WAIT bucket size (increase for high-connection servers)
          "net.ipv4.tcp_max_tw_buckets" = 2000000;

          # SYN backlog (pending connection queue size)
          "net.ipv4.tcp_max_syn_backlog" = 65536;

          # Allow reusing TIME-WAIT sockets for new connections
          "net.ipv4.tcp_tw_reuse" = 1;

          # TIME-WAIT socket timeout (reduce from default 60s)
          "net.ipv4.tcp_fin_timeout" = 5;

          # Disable slow start after idle (maintain congestion window)
          "net.ipv4.tcp_slow_start_after_idle" = 0;

          # TCP keepalive settings (detect dead connections faster)
          "net.ipv4.tcp_keepalive_time" = 30; # Start probing after 30s idle
          "net.ipv4.tcp_keepalive_intvl" = 10; # Probe interval: 10s
          "net.ipv4.tcp_keepalive_probes" = 3; # Declare dead after 3 probes

          # Path MTU discovery (prevent fragmentation issues)
          "net.ipv4.tcp_mtu_probing" = 1;

          # SYN cookies (protect against SYN flood attacks)
          "net.ipv4.tcp_syncookies" = 1;

          # --------------------------------------------------------------------------
          # NETWORK - TCP BUFFER SIZES
          # --------------------------------------------------------------------------
          # Larger buffers improve high-bandwidth, high-latency connections
          "net.core.rmem_default" = 1048576; # Default receive buffer: 1MB
          "net.core.rmem_max" = 16777216; # Max receive buffer: 16MB
          "net.core.wmem_default" = 1048576; # Default send buffer: 1MB
          "net.core.wmem_max" = 16777216; # Max send buffer: 16MB

          # TCP auto-tuning buffer ranges (min default max)
          "net.ipv4.tcp_rmem" = "4096 1048576 16777216"; # 4KB 1MB 16MB
          "net.ipv4.tcp_wmem" = "4096 1048576 16777216"; # 4KB 1MB 16MB

          # Threshold for unsent data (helps reduce bufferbloat)
          "net.ipv4.tcp_notsent_lowat" = 16384;

          # --------------------------------------------------------------------------
          # NETWORK - PACKET PROCESSING
          # --------------------------------------------------------------------------
          # Backlog queue size (packets waiting for CPU processing)
          "net.core.netdev_max_backlog" = 65536;

          # Packet processing budget (packets per NAPI poll)
          "net.core.netdev_budget" = 50000;

          # Maximum socket listen backlog
          "net.core.somaxconn" = 65535;

          # Ancillary buffer size (cmsg)
          "net.core.optmem_max" = 65536;

          # --------------------------------------------------------------------------
          # NETWORK - UDP OPTIMIZATIONS
          # --------------------------------------------------------------------------
          "net.ipv4.udp_rmem_min" = 8192; # Min UDP receive buffer
          "net.ipv4.udp_wmem_min" = 8192; # Min UDP send buffer

          # --------------------------------------------------------------------------
          # NETWORK - ADDITIONAL TCP OPTIONS
          # --------------------------------------------------------------------------
          # Explicit Congestion Notification (ECN)
          "net.ipv4.tcp_ecn" = 1; # Enable ECN for congestion signaling

          # Selective Acknowledgment (SACK) options
          "net.ipv4.tcp_dsack" = 1; # Duplicate SACK (detect spurious retransmits)
          "net.ipv4.tcp_fack" = 1; # Forward Acknowledgment
          "net.ipv4.tcp_sack" = 1; # Enable SACK

          # TCP timestamps (needed for RTT calculation, PAWS)
          "net.ipv4.tcp_timestamps" = 1;

          # TCP window scaling (allow windows > 64KB)
          "net.ipv4.tcp_window_scaling" = 1;

          # Window scaling factor (negative = more aggressive)
          "net.ipv4.tcp_adv_win_scale" = -2;

          # Auto-tune receive buffers based on traffic
          "net.ipv4.tcp_moderate_rcvbuf" = 1;

          # Don't save TCP metrics on connection close
          "net.ipv4.tcp_no_metrics_save" = 1;

          # TIME-WAIT assassination protection (drop RST in TIME-WAIT)
          "net.ipv4.tcp_rfc1337" = 1;

          # SYN-ACK retry limit (reduce from default 5)
          "net.ipv4.tcp_synack_retries" = 2;

          # TCP retry limit for established connections
          "net.ipv4.tcp_retries2" = 8;

          # --------------------------------------------------------------------------
          # NETWORK - IP FORWARDING (REQUIRED FOR NAT/ROUTING)
          # --------------------------------------------------------------------------
          # IPv4 forwarding
          "net.ipv4.conf.all.forwarding" = lib.mkForce 1;
          "net.ipv4.conf.default.forwarding" = lib.mkForce 1;
          "net.ipv4.conf.*.forwarding" = lib.mkForce 1;

          # IPv6 forwarding
          "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
          "net.ipv6.conf.default.forwarding" = lib.mkForce 1;
          "net.ipv6.conf.*.forwarding" = lib.mkForce 1;

          # --------------------------------------------------------------------------
          # NETWORK - REVERSE PATH FILTERING (DISABLED FOR COMPATIBILITY)
          # --------------------------------------------------------------------------
          # rp_filter disabled to allow asymmetric routing
          "net.ipv4.conf.all.rp_filter" = lib.mkForce 0;
          "net.ipv4.conf.default.rp_filter" = lib.mkForce 0;
          "net.ipv4.conf.*.rp_filter" = lib.mkForce 0;

          # --------------------------------------------------------------------------
          # NETWORK - ICMP REDIRECTS (DISABLED FOR SECURITY)
          # --------------------------------------------------------------------------
          # Accept redirects
          "net.ipv4.conf.all.accept_redirects" = lib.mkForce 0;
          "net.ipv4.conf.default.accept_redirects" = lib.mkForce 0;
          "net.ipv4.conf.*.accept_redirects" = lib.mkForce 0;

          # Accept secure redirects
          "net.ipv4.conf.all.secure_redirects" = 0;
          "net.ipv4.conf.default.secure_redirects" = 0;
          "net.ipv4.conf.*.secure_redirects" = 0;

          # Send redirects
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
          "net.ipv4.conf.*.send_redirects" = 0;

          # IPv6 redirects
          "net.ipv6.conf.all.accept_redirects" = lib.mkForce 0;
          "net.ipv6.conf.default.accept_redirects" = lib.mkForce 0;
          "net.ipv6.conf.*.accept_redirects" = lib.mkForce 0;

          # --------------------------------------------------------------------------
          # NETWORK - ARP SETTINGS
          # --------------------------------------------------------------------------
          # ARP ignore/announce for multi-homed systems
          # Prevents responding to ARP on wrong interface
          "net.ipv4.conf.all.arp_ignore" = 0;
          "net.ipv4.conf.default.arp_ignore" = 1;
          "net.ipv4.conf.all.arp_announce" = 0;
          "net.ipv4.conf.default.arp_announce" = 2;
        };
      };
    })
    // (mkIf (cfg.enable && cfg.scx.enable) {
      # https://wiki.cachyos.org/configuration/sched-ext/

      environment.systemPackages = [ pkgs.scx.rustscheds ];

      boot.kernelPatches = [
        {
          name = "scx-patches";
          patch = null;
          structuredExtraConfig = with lib.kernel; {
            BPF = yes;
            BPF_SYSCALL = yes;
            BPF_JIT = lib.mkForce yes;
            DEBUG_INFO_BTF = yes;
            BPF_JIT_ALWAYS_ON = lib.mkForce yes;
            BPF_JIT_DEFAULT_ON = yes;
            SCHED_CLASS_EXT = yes;
          };
        }
      ];

      # ============================================================================
      # POWER MODE SWITCHING (Battery/AC)
      # ============================================================================
      # Automatically switches scheduler between powersave and performance modes
      # based on power supply status. Uses udev rules to detect AC adapter changes.

      services.udev.extraRules = ''
        # Trigger scx power mode switch when AC adapter is connected/disconnected
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start scx-powersave.service"
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start scx-performance.service"
      '';

      # Disable the default scx service since we manage it manually
      systemd.services = {
        scx.enable = lib.mkForce false;

        scx-powersave = {
          description = "scx scheduler (powersave mode for battery)";
          after = [ "basic.target" ];
          conflicts = [ "scx-performance.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "battery" ''
              echo ${cfg.scx.battery.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
              ${pkgs.scx.rustscheds}/bin/${cfg.scx.battery.scheduler} \
                ${cfg.scx.battery.args} \
                ${cfg.scx.battery.extraArgs}
            '';
            ExecStartPre = "-${pkgs.systemd}/bin/systemctl stop scx-performance.service";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        scx-performance = {
          description = "scx scheduler (performance mode for AC)";
          after = [ "basic.target" ];
          conflicts = [ "scx-powersave.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "ac" ''
              echo ${cfg.scx.ac.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
              ${pkgs.scx.rustscheds}/bin/${cfg.scx.ac.scheduler} \
                ${cfg.scx.ac.args} \
                ${cfg.scx.ac.extraArgs}
            '';
            ExecStartPre = "-${pkgs.systemd}/bin/systemctl stop scx-powersave.service";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        # Service to set initial scx mode based on power status at boot
        scx-init = {
          description = "Initialize scx power mode based on AC status";
          wantedBy = [
            "multi-user.target"
            "post-resume.target"
          ];
          after = [
            "systemd-udev-settle.service"
            "post-resume.target"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "scx-init" ''
              # Check if we're on AC power
              AC_ONLINE=0
              for psu in /sys/class/power_supply/*/online; do
                if [ -f "$psu" ]; then
                  STATUS=$(cat "$psu" 2>/dev/null || echo 0)
                  if [ "$STATUS" = "1" ]; then
                    AC_ONLINE=1
                    break
                  fi
                fi
              done

              if [ "$AC_ONLINE" = "1" ]; then
                echo "AC power detected, starting performance mode"
                ${pkgs.systemd}/bin/systemctl start scx-performance.service
              else
                echo "Battery power detected, starting powersave mode"
                ${pkgs.systemd}/bin/systemctl start scx-powersave.service
              fi
            '';
          };
        };
      };
    });
}
