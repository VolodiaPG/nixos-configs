{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.kernel;
in {
  options = {
    services.kernel = with types; {
      enable = mkEnableOption "kernel";

      zfsTweaks = mkOption {
        description = "enable ZFS Zen tweaks on any kernel (relevant for CFS only)";
        type = types.bool;
        default = false;
      };
    };
  };

  config =
    mkIf cfg.enable
    {
      powerManagement = {
        enable = true;
        cpuFreqGovernor = "powersave";
        powertop.enable = true;
      };
      services = {
        power-profiles-daemon.enable = true;
        thermald.enable = true;
        acpid.enable = true;
      };
      # services.tlp.enable = true;
      # services.tlp.settings = {
      #   CPU_BOOST_ON_BAT = 1;
      #   CPU_BOOST_ON_AC = 1;
      #   CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      #   CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      #   START_CHARGE_THRESH_BAT0 = 90;
      #   STOP_CHARGE_THRESH_BAT0 = 97;
      #   RUNTIME_PM_ON_BAT = "auto";
      # };

      systemd.services.cfs-zen-tweaks = mkIf cfg.zfsTweaks {
        description = "Zen CFS tweaks";

        wantedBy = ["multi-user.target" "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash ${pkgs.cfs-zen-tweaks}/lib/cfs-zen-tweaks/set-cfs-zen-tweaks.bash";
        };
      };

      boot = {
        tmp.cleanOnBoot = true;

        /*
        NOTE: replace this with your desired kernel, see: https://nixos.wiki/wiki/Linux_kernel for reference.
        If you're not me or a XanMod kernel maintainer in Nixpkgs, use pkgs.linuxKernel.packages.linux_xanmod instead to avoid compilation.
        */
        # kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor pkgs.linux-cachyos);
        #kernelPackages = pkgs-unstable.recurseIntoAttrs (pkgs-unstable.linuxPackagesFor pkgs-unstable.linux-xanmod-volodiapg);
        #kernelPackages = pkgs.linuxPackages-rt_latest;
        # kernelPackages = pkgs.linuxPackages_zen;
        # kernelPackages = pkgs.linuxPackages_xanmod_latest;
        kernelPackages = pkgs.linuxPackages_latest;

        # resumeDevice = "/dev/mapper/lvm-swap";

        #kernelParams = [
        #noibrs"
        #  "noibpb"
        #  "nopti"
        #  "nospectre_v2"
        #  "nospectre_v1"
        #  "l1tf=off"
        #  "nospec_store_bypass_disable"
        #  "no_stf_barrier"
        #  "mds=off"
        #  "tsx=on"
        #   "tsx_async_abort=off"
        #   "mitigations=off"
        #];

        kernelParams = [
          # "ahci.mobile_lpm_policy=3"
          # "intel_pstate=disable" # switch to acpi-cpufreq instead
          # "enable_guc=3"
        ];

        kernel.sysctl = {
          # # "kernel.sched_migration_cost_ns" = 5000000;
          # # "kernel.sched_nr_fork_threshold" = 3;
          # "kernel.sched_fake_interactive_win_time_ms" = 1000;
          # # "net.ipv4.tcp_keepalive_time" = 60;
          # # "net.ipv4.tcp_keepalive_intvl" = 10;
          # # "net.ipv4.tcp_keepalive_probes" = 6;
          # # "net.ipv4.conf.default.log_martians" = 1;
          # # "net.ipv4.conf.all.log_martians" = 1;
          # "net.ipv4.tcp_mtu_probing" = 1;

          # # The swappiness sysctl parameter represents the kernel's preference (or avoidance) of swap space. Swappiness can have a value between 0 and 100, the default value is 60.
          # # A low value causes the kernel to avoid swapping, a higher value causes the kernel to try to use swap space. Using a low value on sufficient memory is known to improve responsiveness on many systems.
          # "vm.swappiness" = 1;

          # # The value controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects (VFS cache).
          # # Lowering it from the default value of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this may produce out-of-memory conditions)
          # #vm.vfs_cache_pressure=50

          # # Contains, as a percentage of total available memory that contains free pages and reclaimable
          # # pages, the number of pages at which a process which is generating disk writes will itself start
          # # writing out dirty data (Default is 20).
          # "vm.dirty_ratio" = 3;

          # # page-cluster controls the number of pages up to which consecutive pages are read in from swap in a single attempt.
          # # This is the swap counterpart to page cache readahead. The mentioned consecutivity is not in terms of virtual/physical addresses,
          # # but consecutive on swap space - that means they were swapped out together. (Default is 3)
          # # increase this value to 1 or 2 if you are using physical swap (1 if ssd, 2 if hdd)
          # "vm.page-cluster" = 0;

          # # Contains, as a percentage of total available memory that contains free pages and reclaimable
          # # pages, the number of pages at which the background kernel flusher threads will start writing out
          # # dirty data (Default is 10).
          # "vm.dirty_background_ratio" = 2;

          # # This tunable is used to define when dirty data is old enough to be eligible for writeout by the
          # # kernel flusher threads.  It is expressed in 100'ths of a second.  Data which has been dirty
          # # in-memory for longer than this interval will be written out next time a flusher thread wakes up
          # # (Default is 3000).
          # #vm.dirty_expire_centisecs = 3000

          # # The kernel flusher threads will periodically wake up and write old data out to disk.  This
          # # tunable expresses the interval between those wakeups, in 100'ths of a second (Default is 500).
          # "vm.dirty_writeback_centisecs" = 1500;

          # # This file contains the maximum number of memory map areas a process may have. Memory map areas are used as a side-effect of calling malloc, directly by mmap, mprotect, and madvise, and also when loading shared libraries.
          # # While most applications need less than a thousand maps, certain programs, particularly malloc debuggers, may consume lots of them, e.g., up to one or two maps per allocation.
          # # The default value is 65536
          # "vm.max_map_count" = 16777216;

          # # This action will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption
          # # Disable NMI watchdog
          # "kernel.nmi_watchdog" = 0;

          # # Enable the sysctl setting kernel.unprivileged_userns_clone to allow normal users to run unprivileged containers.
          # "kernel.unprivileged_userns_clone" = 1;

          # # To hide any kernel messages from the console
          # "kernel.printk" = "3 3 3 3";

          # # Restricting access to kernel logs
          # "kernel.dmesg_restrict" = 1;

          # # Restricting access to kernel pointers in the proc filesystem
          # "kernel.kptr_restrict" = 2;

          # # Disable Kexec, which allows replacing the current running kernel.
          # "kernel.kexec_load_disabled" = 1;

          # # Increasing the size of the receive queue.
          # # The received frames will be stored in this queue after taking them from the ring buffer on the network card.
          # # Increasing this value for high speed cards may help prevent losing packets:
          # "net.core.netdev_max_backlog" = 16384;

          # # Increase the maximum connections
          # #The upper limit on how many connections the kernel will accept (default 128):
          # "net.core.somaxconn" = 8192;

          # # Increase the memory dedicated to the network interfaces
          # # The default the Linux network stack is not high, rces:
          # "net.core.rmem_default" = 1048576;
          # "net.core.rmem_max" = 16777216;
          # "net.core.wmem_default" = 1048576;
          # "net.core.wmem_max" = 16777216;
          # "net.core.optmem_max" = 65536;
          # "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
          # "net.ipv4.tcp_wmem" = "4096 65536 16777216";
          # "net.ipv4.udp_rmem_min" = 8192;
          # "net.ipv4.udp_wmem_min" = 8192;

          # # Enable TCP Fast Open
          # # TCP Fast Open is an extension to the transmission control protocol (TCP) that helps reduce network latency
          # # by enabling data to be exchanged during the sender’s initial TCP SYN [3].
          # # Using the value 3 instead of the default 1 allows TCP Fast Open for both incoming and outgoing connections:
          # "net.ipv4.tcp_fastopen" = 3;

          # "net.ipv4.tcp_fin_timeout" = 15;

          # # Decrease the time default value for connections to keep alive
          # "net.ipv4.tcp_keepalive_time" = 300;
          # "net.ipv4.tcp_keepalive_probes" = 5;
          # "net.ipv4.tcp_keepalive_intvl" = 15;

          # # Enable BBR
          # # The BBR congestion control algorithm can help achieve higher bandwidths and lower latencies for internet traffic
          # "net.core.default_qdisc" = "cake"; # "fq_pie"
          # "net.ipv4.tcp_congestion_control" = "bbr2";

          # # TCP SYN cookie protection
          # # Helps protect against SYN flood attacks. Only kicks in when net.ipv4.tcp_max_syn_backlog is reached:
          # "net.ipv4.tcp_syncookies" = 1;

          # # Number of times SYNACKs for passive TCP connection.
          # "net.ipv4.tcp_synack_retries" = 2;

          # # Protect against tcp time-wait assassination hazards, drop RST packets for sockets in the time-wait state. Not widely supported outside of Linux, but conforms to RFC:
          # "net.ipv4.tcp_rfc1337" = 1;

          # # By enabling reverse path filtering, the kernel will do source validation of the packets received from all the interfaces on the machine. This can protect from attackers that are using IP spoofing methods to do harm.
          # "net.ipv4.conf.default.rp_filter" = 1;
          # "net.ipv4.conf.all.rp_filter" = 1;

          # # Disable ICMP redirects
          # "net.ipv4.conf.all.accept_redirects" = 0;
          # "net.ipv4.conf.default.accept_redirects" = 0;
          # "net.ipv4.conf.all.secure_redirects" = 0;
          # "net.ipv4.conf.default.secure_redirects" = 0;
          # "net.ipv6.conf.all.accept_redirects" = 0;
          # "net.ipv6.conf.default.accept_redirects" = 0;
          # "net.ipv4.conf.all.send_redirects" = 0;
          # "net.ipv4.conf.default.send_redirects" = 0;

          # "fs.inotify.max_user_watches" = 524288;
          # "fs.file-max" = 2097152;

          # # Fix Mesa Intel performance support
          # "dev.i915.perf_stream_paranoid" = 0;

          # # increase writeback interval  for xfs
          # "fs.xfs.xfssyncd_centisecs" = 10000;

          # # disable core dumps
          # "kernel.core_pattern" = "/dev/null";

          # "kernel.sched_cfs_bandwidth_slice_us" = 3000;

          # # Sets the time before the kernel considers migrating a proccess to another core
          # "kernel.sched_migration_cost_ns" = 5000000;

          # # Set as default CFS Candidate Balancer - it provides better performance
          # # "kernel.sched_tt_balancer_opt" = 2;

          # # Change PELT multiplier to 16 ms instead of 32ms
          # # 1 = 32ms
          # # 2 = 16ms
          # # 4 = 8ms
          # # "kernel.sched_pelt_multiplier" = 2;

          # # This feature enable CFS priority load balance to reduce
          # # non-idle tasks latency interferenced by SCHED_IDLE tasks.
          # # It prefer migrating non-idle tasks firstly and
          # #  migrating SCHED_IDLE tasks lastly.
          # # "kernel.sched_prio_load_balance_enabled" = 1;

          # # "kernel.sched_tt_balancer_opt" = "1";
        };
      };
    };
}
