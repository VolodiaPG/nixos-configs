{
  pkgs,
  lib,
  config,
  flake,
  ...
}:
let
  inherit (flake.config) me;
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
      pkgs.theme-switcher
    ];

    # macOS: Use dark-mode-notify
    launchd.agents.theme-daemon = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.dark-mode-notify}/bin/dark-mode-notify"
          "${pkgs.theme-switcher}/bin/theme-switcher"
        ];
        EnvironmentVariables = {
          PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/etc/profiles/per-user/${me.username}/bin";
        };
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = "${config.home.homeDirectory}/.local/state/theme-switcher/dark-mode-notify.log";
        StandardOutPath = "${config.home.homeDirectory}/.local/state/theme-switcher/dark-mode-notify.log";
      };
    };

    services.darkman = {
      enable = isLinux;
      settings = {
        usegeoclue = true;
      };
      darkModeScripts = {
        theme-switcher = ''
          ${pkgs.theme-switcher}/bin/theme-switcher dark
        '';
      };
      lightModeScripts = {
        theme-switcher = ''
          ${pkgs.theme-switcher}/bin/theme-switcher light
        '';
      };
    };

    home = {
      # Create state directory
      activation.createThemeStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/state/theme-switcher
      '';
    };
  };
}
