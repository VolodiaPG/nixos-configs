{
  config,
  ...
}:
let
  inherit (config) me;
in
{
  config.home.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
    in
    {
      home.packages = [
        pkgs.theme-switcher
      ];

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
        activation.createThemeStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/state/theme-switcher
        '';
      };
    };
}
