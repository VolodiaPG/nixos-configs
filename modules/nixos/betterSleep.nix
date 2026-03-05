{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.betterSleep;
in
{
  options = {
    services.betterSleep = {
      enable = mkEnableOption "sleep mode with powersave CPU governor";
    };
  };

  config = mkIf cfg.enable {
    # Save current state and apply sleep settings
    powerManagement.powerDownCommands = ''
      # Save the current governor from CPU0 (assumes all cores use the same governor)
      cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /run/cpu-governor-before-sleep 2>/dev/null || true

      # Set powersave for all CPUs
      echo powersave > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    '';

    # Restore the previous state on wake
    powerManagement.powerUpCommands = ''
      # Restore CPU governor
      if [ -f /run/cpu-governor-before-sleep ]; then
        GOVERNOR=$(cat /run/cpu-governor-before-sleep)
        echo "$GOVERNOR" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        rm -f /run/cpu-governor-before-sleep
      fi
    '';
  };
}
