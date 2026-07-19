{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nirius;
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options.nirius = {
    enable = mkEnableOption "Nirius utility for niri";

    scratchpads = mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            appId = mkOption {
              type = lib.types.str;
              description = "The app-id to match for this scratchpad";
            };
            spawn = mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Command to spawn if the app isn't running";
            };
          };
        }
      );
      default = [ ];
      description = "List of scratchpad configurations";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.nirius ];

    # Start niriusd daemon via systemd user service
    systemd.user.services.niriusd = {
      Unit = {
        Description = "Nirius daemon for niri scratchpad functionality";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.nirius}/bin/niriusd";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
