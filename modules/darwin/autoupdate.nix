{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
with lib;
let
  inherit (flake.config) me;
  cfg = config.services.darwinAutoUpdate;

  # The main update script
  updateScript = pkgs.writeShellScriptBin "nix-darwin-autoupdate" ''
    set -uo pipefail

    # Configuration (injected from module)
    FLAKE="${cfg.flake}"
    HOST="${cfg.hostName}"
    INTERVAL="${toString cfg.interval}"
    STATE_DIR="${cfg.stateDir}"
    TIMESTAMP_FILE="$STATE_DIR/last-update"
    REVISION_FILE="$STATE_DIR/last-revision"
    LOG_FILE="${cfg.logFile}"
    NOTIFY_USER="${me.username}"

    # Ensure state directory exists
    mkdir -p "$STATE_DIR"

    log() {
      echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"
    }

    notify() {
      local title="$1"
      local message="$2"
      # Run terminal-notifier as the user to show in their notification center
      sudo -u "$NOTIFY_USER" ${pkgs.terminal-notifier}/bin/terminal-notifier \
        -title "$title" \
        -message "$message" \
        -group "nix-darwin-autoupdate" \
        -ignoreDnD
    }

    cleanup() {
      log "Script interrupted, cleaning up..."
      exit 1
    }
    trap cleanup SIGINT SIGTERM

    # 1. Check network connectivity
    log "Checking network connectivity..."
    if ! ${pkgs.curl}/bin/curl -s --max-time 10 --head https://github.com > /dev/null 2>&1; then
      log "No network connectivity to GitHub, skipping update"
      exit 0
    fi

    # 2. Check if enough time has passed since last update
    if [[ -f "$TIMESTAMP_FILE" ]]; then
      last_update=$(cat "$TIMESTAMP_FILE")
      now=$(date +%s)
      elapsed=$((now - last_update))
      if [[ $elapsed -lt $INTERVAL ]]; then
        log "Skipping: only ''${elapsed}s since last update (need ''${INTERVAL}s)"
        exit 0
      fi
    fi

    # 3. Get remote revision
    log "Checking for updates from $FLAKE..."
    remote_metadata=$(${pkgs.nix}/bin/nix flake metadata "$FLAKE" --json --refresh 2>/dev/null) || {
      log "Failed to fetch flake metadata"
      notify "nix-darwin Update" "Failed to fetch updates from GitHub"
      exit 1
    }
    remote_rev=$(echo "$remote_metadata" | ${pkgs.jq}/bin/jq -r '.revision // empty')
    remote_lastmod=$(echo "$remote_metadata" | ${pkgs.jq}/bin/jq -r '.lastModified // empty')

    if [[ -z "$remote_rev" ]]; then
      log "Could not determine remote revision"
      exit 1
    fi

    # 4. Compare with last applied revision
    local_rev=""
    [[ -f "$REVISION_FILE" ]] && local_rev=$(cat "$REVISION_FILE")

    if [[ "$remote_rev" == "$local_rev" ]]; then
      log "No updates available (rev: $remote_rev)"
      date +%s > "$TIMESTAMP_FILE"
      exit 0
    fi

    # 5. Get current generation for potential rollback
    log "Saving current generation for rollback..."
    current_gen=$(${pkgs.nix}/bin/nix-env --list-generations -p /nix/var/nix/profiles/system 2>/dev/null | tail -1 | awk '{print $1}') || current_gen=""
    log "Current generation: $current_gen"

    # 6. Apply update
    short_rev="''${remote_rev:0:7}"
    log "Update available: ''${local_rev:0:7} -> $short_rev"
    log "Running darwin-rebuild switch..."
    notify "nix-darwin Update" "Updating to $short_rev..."

    if ${pkgs.nix}/bin/nix build "$FLAKE#darwinConfigurations.$HOST.system" --no-link >> "$LOG_FILE" 2>&1; then
      log "Build successful, switching..."

      if /run/current-system/sw/bin/darwin-rebuild switch --flake "$FLAKE#$HOST" >> "$LOG_FILE" 2>&1; then
        log "Update successful! Now at revision: $short_rev"
        date +%s > "$TIMESTAMP_FILE"
        echo "$remote_rev" > "$REVISION_FILE"
        notify "nix-darwin Update" "Successfully updated to $short_rev"
        exit 0
      else
        log "Switch FAILED!"
      fi
    else
      log "Build FAILED!"
    fi

    # 7. Rollback on failure
    log "Update failed, attempting rollback..."
    notify "nix-darwin Update" "Update failed, rolling back..."

    if [[ -n "$current_gen" ]]; then
      if /run/current-system/sw/bin/darwin-rebuild switch --rollback >> "$LOG_FILE" 2>&1; then
        log "Rollback successful"
        notify "nix-darwin Update" "Rolled back after failed update. Check logs: $LOG_FILE"
      else
        log "Rollback FAILED! Manual intervention required."
        notify "nix-darwin Update" "CRITICAL: Rollback failed! Check $LOG_FILE"
      fi
    else
      log "No previous generation found for rollback"
      notify "nix-darwin Update" "Update failed, no rollback available. Check $LOG_FILE"
    fi

    exit 1
  '';

  # Log rotation script
  logRotateScript = pkgs.writeShellScriptBin "nix-darwin-autoupdate-logrotate" ''
    LOG_FILE="${cfg.logFile}"
    MAX_SIZE="${toString cfg.logMaxSize}"
    KEEP_LOGS="${toString cfg.logKeepCount}"

    if [[ -f "$LOG_FILE" ]]; then
      size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo "0")
      if [[ $size -gt $MAX_SIZE ]]; then
        # Rotate logs
        for i in $(seq $((KEEP_LOGS - 1)) -1 1); do
          [[ -f "$LOG_FILE.$i" ]] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
        done
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
        echo "[$(date -Iseconds)] Log rotated" >> "$LOG_FILE"
      fi
    fi
  '';
in
{
  options.services.darwinAutoUpdate = {
    enable = mkEnableOption "Automatic nix-darwin and home-manager updates from GitHub";

    flake = mkOption {
      type = types.str;
      default = "github:volodiapg/nixos-configs";
      description = "Flake URL to pull updates from";
    };

    hostName = mkOption {
      type = types.str;
      default = "Volodias-MacBook-Pro";
      description = "Darwin configuration name in the flake";
    };

    interval = mkOption {
      type = types.int;
      default = 86400;
      description = "Minimum interval between update attempts in seconds (default: 24 hours)";
    };

    checkInterval = mkOption {
      type = types.int;
      default = 3600;
      description = "How often launchd runs the check script in seconds (default: 1 hour)";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/nix-darwin-autoupdate";
      description = "Directory to store state files (timestamps, revisions)";
    };

    logFile = mkOption {
      type = types.str;
      default = "/var/log/nix-darwin-autoupdate.log";
      description = "Path to the log file";
    };

    logMaxSize = mkOption {
      type = types.int;
      default = 10485760; # 10 MB
      description = "Maximum log file size in bytes before rotation";
    };

    logKeepCount = mkOption {
      type = types.int;
      default = 3;
      description = "Number of rotated log files to keep";
    };
  };

  config = mkIf cfg.enable {
    # Ensure state directory exists via activation script
    system.activationScripts.postActivation.text = ''
      echo "Setting up nix-darwin-autoupdate state directory..."
      mkdir -p ${cfg.stateDir}
      touch ${cfg.logFile}
    '';

    # Main auto-update daemon
    launchd.daemons.nix-darwin-autoupdate = {
      serviceConfig = {
        ProgramArguments = [ "${updateScript}/bin/nix-darwin-autoupdate" ];

        # Run at the specified interval
        StartInterval = cfg.checkInterval;

        # Also run at load (catches missed updates after sleep/reboot)
        RunAtLoad = true;

        # Run as root (needed for darwin-rebuild switch)
        UserName = "root";

        # Logging handled by script, but capture any unexpected output
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;

        # Process settings
        Nice = 10; # Lower priority
        ProcessType = "Background";
        LowPriorityBackgroundIO = true;

        # Don't restart on success, only on crash
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };

        # Timeout after 30 minutes (builds can take a while)
        TimeOut = 1800;

        # Environment variables
        EnvironmentVariables = {
          PATH = lib.makeBinPath [
            pkgs.nix
            pkgs.jq
            pkgs.coreutils
            pkgs.curl
            pkgs.gnused
            pkgs.gawk
            "/run/current-system/sw"
          ];
          NIX_PATH = "nixpkgs=flake:nixpkgs";
          HOME = "/var/root";
        };
      };
    };

    # Log rotation daemon - runs daily
    launchd.daemons.nix-darwin-autoupdate-logrotate = {
      serviceConfig = {
        ProgramArguments = [ "${logRotateScript}/bin/nix-darwin-autoupdate-logrotate" ];

        # Run once per day
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 0;
          }
        ];

        UserName = "root";
        Nice = 19;
        ProcessType = "Background";
        LowPriorityBackgroundIO = true;
      };
    };
  };
}
