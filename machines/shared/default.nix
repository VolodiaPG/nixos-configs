{ config, lib, pkgs, options, inputs, system, ... }:
{
  powerManagement.cpuFreqGovernor = "performance";
  boot = {
    /*
      NOTE: replace this with your desired kernel, see: https://nixos.wiki/wiki/Linux_kernel for reference.
      If you're not me or a XanMod kernel maintainer in Nixpkgs, use pkgs.linuxKernel.packages.linux_xanmod instead to avoid compilation.
    */
    # kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    # kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_tt;
    kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage ../../pkgs/linux-xanmod-volodiapg { }));

    #kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelParams = [
      "noibrs"
      "noibpb"
      "nopti"
      "nospectre_v2"
      "nospectre_v1"
      "l1tf=off"
      "nospec_store_bypass_disable"
      "no_stf_barrier"
      "mds=off"
      "tsx=on"
      "tsx_async_abort=off"
      "mitigations=off"
    ];

    kernel.sysctl = {
      "fs.file-max" = 2097152;
      "kernel.printk" = "3 3 3 3";
      "kernel.sched_migration_cost_ns" = 5000000;
      "kernel.sched_nr_fork_threshold" = 3;
      "kernel.sched_fake_interactive_win_time_ms" = 1000;
      "kernel.unprivileged_userns_clone" = 1;
      "net.core.default_qdisc" = "fq_pie";
      "vm.dirty_ratio" = 3;
      "vm.dirty_background_ratio" = 2;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.core.rmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 1048576;
      "net.core.wmem_max" = 16777216;
      "net.core.optmem_max" = 65536;
      "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.udp_rmem_min" = 8192;
      "net.ipv4.udp_wmem_min" = 8192;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_keepalive_time" = 60;
      "net.ipv4.tcp_keepalive_intvl" = 10;
      "net.ipv4.tcp_keepalive_probes" = 6;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_congestion_control" = "bbr2";

      # "kernel.sched_tt_balancer_opt" = "1";
    };
  };
}
