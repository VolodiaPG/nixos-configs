_: {
  config.nixos.scx =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
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
        "scx_cake"
        "scx_beerland"
      ];

      sources = pkgs.callPackage (../_sources/generated.nix) { };
      rustsched =
        sched:
        pkgs.scx.rustscheds.overrideAttrs (_old: {
          version = "${sources.scx.date}-${sources.scx.version}";
          inherit (sources.scx) src;
          doCheck = false;
          cargoBuildFlags = [
            "-p"
            sched
          ];
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            inherit (sources.scx.cargoLock."Cargo.lock") lockFile outputHashes;
          };
        });
    in
    {
      options.services.myScx = with types; {
        battery = {
          scheduler = mkOption {
            description = "scx scheduler to use on battery power";
            type = scheds;
            default = "scx_cosmos";
          };
          args = mkOption {
            description = "Command line arguments for the battery scheduler";
            type = types.str;
            default = lib.concatStrings [
              " --slice-us 3000"
              " --cpu-busy-thresh 80"
              " --polling-ms 100"
              " --preferred-idle-scan"
              " --mm-affinity"
            ];
          };
          extraArgs = mkOption {
            description = "Extra arguments for the battery scheduler";
            type = types.str;
            default = "--primary-domain powersave";
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
            default = lib.concatStrings [
              " --slice-us 1000"
              " --cpu-busy-thresh 50"
              " --polling-ms 50"
              " --preferred-idle-scan"
              " --mm-affinity"
            ];
          };
          extraArgs = mkOption {
            description = "Extra arguments for the AC scheduler";
            type = types.str;
            default = "--primary-domain performance";
          };
          governor = mkOption {
            description = "CPU governor to use for the AC scheduler";
            type = types.str;
            default = "schedutil";
          };
        };
      };

      config = {
        boot.kernel.sysctl = {
          "kernel.sched_autogroup_enabled" = 1;
          "kernel.sched_child_runs_first" = 0;
        };

        environment.systemPackages = [
          (rustsched config.services.myScx.ac.scheduler)
          (rustsched config.services.myScx.battery.scheduler)
        ];

        services.udev.extraRules = ''
          SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start scx-powersave.service"
          SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start scx-performance.service"
        '';

        systemd.services = {
          scx.enable = lib.mkForce false;

          scx-powersave = {
            description = "scx scheduler (powersave mode for battery)";
            after = [ "basic.target" ];
            conflicts = [ "scx-performance.service" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = pkgs.writeShellScript "battery" ''
                echo ${config.services.myScx.battery.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
                ${rustsched config.services.myScx.battery.scheduler}/bin/${config.services.myScx.battery.scheduler} \
                  ${config.services.myScx.battery.args} \
                  ${config.services.myScx.battery.extraArgs}
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
                echo ${config.services.myScx.ac.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
                ${rustsched config.services.myScx.battery.scheduler}/bin/${config.services.myScx.ac.scheduler} \
                  ${config.services.myScx.ac.args} \
                  ${config.services.myScx.ac.extraArgs}
              '';
              ExecStartPre = "-${pkgs.systemd}/bin/systemctl stop scx-powersave.service";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

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
                AC_ONLINE=1
                for psu in /sys/class/power_supply/*/online; do
                  AC_ONLINE=0
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
      };
    };
}
