{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.backlightOff;

  # Script to turn off backlight
  backlightOffScript = pkgs.writeShellScript "backlight-off" ''
    BACKLIGHT_PATH="/sys/class/backlight/intel_backlight"

    if [ ! -d "$BACKLIGHT_PATH" ]; then
      echo "Backlight path not found: $BACKLIGHT_PATH" >&2
      exit 1
    fi

    # Save current brightness if not already saved
    if [ ! -f /var/lib/backlight-off/brightness-save ]; then
      mkdir -p /var/lib/backlight-off
      cat "$BACKLIGHT_PATH/brightness" > /var/lib/backlight-off/brightness-save
    fi

    # Turn off backlight
    echo 0 > "$BACKLIGHT_PATH/brightness"
  '';

  # Script to restore backlight
  backlightOnScript = pkgs.writeShellScript "backlight-on" ''
    BACKLIGHT_PATH="/sys/class/backlight/intel_backlight"

    if [ ! -d "$BACKLIGHT_PATH" ]; then
      exit 0
    fi

    # Restore saved brightness or set to max
    if [ -f /var/lib/backlight-off/brightness-save ]; then
      cat /var/lib/backlight-off/brightness-save > "$BACKLIGHT_PATH/brightness"
      rm -f /var/lib/backlight-off/brightness-save
    else
      # Set to max brightness as fallback
      cat "$BACKLIGHT_PATH/max_brightness" > "$BACKLIGHT_PATH/brightness"
    fi
  '';
in
{
  options.services.backlightOff = {
    enable = mkEnableOption "automatic screen dimming after idle period";

    idleTime = mkOption {
      type = types.int;
      default = 15;
      description = ''
        Number of minutes of inactivity before turning off the screen.
      '';
    };

    brightnessPath = mkOption {
      type = types.str;
      default = "/sys/class/backlight/intel_backlight";
      description = ''
        Path to the backlight brightness control file.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = with pkgs; [
      coreutils
    ];

    # Create systemd service to turn off backlight
    systemd = {
      services = {
        backlight-off = {
          description = "Turn off screen backlight after idle";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = backlightOffScript;
            User = "root";
            StateDirectory = "backlight-off";
          };
        };

        # Create systemd service to restore backlight
        backlight-on = {
          description = "Restore screen backlight on activity";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = backlightOnScript;
            User = "root";
          };
        };
        backlight-idle-check = {
          description = "Check idle time and control backlight";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = ''
            IDLE_TIME_LIMIT=${toString (cfg.idleTime * 60 * 1000000)}  # Convert minutes to microseconds

            # Check if logind is tracking idle time
            if [ -S /run/systemd/private ]; then
              # Get idle time via logind (requires dbus)
              IDLE_TIME=$(${pkgs.dbus}/bin/dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.DBus.Properties.Get string:org.freedesktop.login1.Manager string:IdleSinceHint 2>/dev/null | ${pkgs.gawk}/bin/awk '/uint64/ {print $2}' || echo "0")

              if [ -n "$IDLE_TIME" ] && [ "$IDLE_TIME" != "0" ]; then
                CURRENT_TIME=$(${pkgs.coreutils}/bin/date +%s%6N)
                IDLE_DURATION=$((CURRENT_TIME - IDLE_TIME))

                if [ "$IDLE_DURATION" -ge "$IDLE_TIME_LIMIT" ]; then
                  ${pkgs.systemd}/bin/systemctl start backlight-off
                else
                  ${pkgs.systemd}/bin/systemctl start backlight-on
                fi
              fi
            fi
          '';
        };

      };

      # Create a systemd timer that checks for idle time
      # This uses a simpler approach: a timer that runs every minute
      # and a script that checks idle time via logind or input devices
      timers.backlight-idle-check = {
        description = "Check for idle time to turn off backlight";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
        };
      };
    };

    # Ensure the backlight path is writable
    boot.kernelModules = [ "i915" ]; # Intel graphics driver for backlight control
  };
}
