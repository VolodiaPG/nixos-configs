{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.myScx;
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
    services.myScx = with types; {
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
          default = lib.concatStrings [
            " --slice-us 3000"
            " --cpu-busy-thresh 80"
            " --polling-ms 100"
            " --preferred-idle-scan"
            " --mm-affinity"
          ];
        };

        # https://github.com/dougallj/applecpu/blob/main/timer-hacks/bench.py#L85

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
  };

  config = mkIf cfg.enable {
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
            echo ${cfg.battery.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
            ${pkgs.scx.rustscheds}/bin/${cfg.battery.scheduler} \
              ${cfg.battery.args} \
              ${cfg.battery.extraArgs}
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
            echo ${cfg.ac.governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
            ${pkgs.scx.rustscheds}/bin/${cfg.ac.scheduler} \
              ${cfg.ac.args} \
              ${cfg.ac.extraArgs}
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
  };
}
