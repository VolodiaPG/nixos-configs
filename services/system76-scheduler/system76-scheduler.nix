{ config, pkgs, lib, ... }:


{
  options = {
    services.system76Scheduler = with lib; with types; {
      enable = mkEnableOption "system76Scheduler";

      package = mkOption {
        description = "system76Scheduler package";
        defaultText = "pkgs.system76Scheduler";
        type = package;
        default = pkgs.callPackage ../../pkgs/system76-scheduler { };
      };
    };
  };

  ### Implementation ###

  config =
    let
      cfg = config.services.system76Scheduler;
    in
    lib.mkIf cfg.enable {
      systemd.services.system76Scheduler = {
        enable = cfg.enable;
        wantedBy = [ "multi-user.target" ];

        description = "Automatically configure CPU scheduler for responsiveness on AC";
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/system76-scheduler daemon";
          ExecReload = "${cfg.package}/bin/system76-scheduler daemon reload";
          Type = "dbus";
          BusName = "com.system76.Scheduler";
        };
      };

      environment.systemPackages = [
        (cfg.package)
      ];
    };
}
