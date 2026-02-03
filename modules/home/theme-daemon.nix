{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  themeSwitcher = pkgs.writeShellScriptBin "theme-switcher" (builtins.readFile ./theme-switcher.sh);

  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
in
{
  options = {
    services.theme-daemon = {
      enable = lib.mkEnableOption "automatic theme switching daemon";
    };
  };

  config = lib.mkIf config.services.theme-daemon.enable {
    home.packages = [
      themeSwitcher
      pkgs.neovim-remote
    ];

    # macOS: Use dark-mode-notify
    launchd.agents.theme-daemon = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.dark-mode-notify}/bin/dark-mode-notify"
          "${themeSwitcher}/bin/theme-switcher"
        ];
        EnvironmentVariables = {
          PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/etc/profiles/per-user/${user.username}/bin";
        };
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = "${config.home.homeDirectory}/.local/state/theme-switcher/dark-mode-notify.log";
        StandardOutPath = "${config.home.homeDirectory}/.local/state/theme-switcher/dark-mode-notify.log";
      };
    };

    # Linux: Use darkman
    systemd.user.services.theme-daemon = lib.mkIf isLinux {
      Unit = {
        Description = "Darkman theme daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "nl.whynothugo.darkman";
        ExecStart = "${pkgs.darkman}/bin/darkman run";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home = {
      # Linux: Darkman configuration
      file.".config/darkman/light-mode.d/theme-switcher.sh" = lib.mkIf isLinux {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          ${themeSwitcher}/bin/theme-switcher light
        '';
      };

      file.".config/darkman/dark-mode.d/theme-switcher.sh" = lib.mkIf isLinux {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          ${themeSwitcher}/bin/theme-switcher dark
        '';
      };

      # Create state directory
      activation.createThemeStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/state/theme-switcher
      '';
    };
  };
}
