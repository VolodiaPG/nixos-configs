_: {
  config.nixos.desktop =
    {
      lib,
      ...
    }:
    with lib;
    {
      powerManagement.powerDownCommands = ''
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /run/cpu-governor-before-sleep 2>/dev/null || true
        echo powersave > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
      '';

      powerManagement.powerUpCommands = ''
        if [ -f /run/cpu-governor-before-sleep ]; then
          GOVERNOR=$(cat /run/cpu-governor-before-sleep)
          echo "$GOVERNOR" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
          rm -f /run/cpu-governor-before-sleep
        fi
      '';
    };
}
