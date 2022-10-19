{ config, pkgs, lib, ... }:


let scheduler = pkgs.callPackage ../../pkgs/system76-scheduler { }; in
{
  options = {
    services.system76Scheduler = with lib; with types; {
      enable = mkEnableOption "system76Scheduler";

      package = mkOption {
        description = "system76Scheduler package";
        defaultText = literalExpression "pkgs.system76Scheduler";
        type = package;
        default = scheduler;
      };

      assignments = mkOption {
        description = "Priority Assignments";
        type = lines;
        default = builtins.readFile "${scheduler}/etc/system76-scheduler/assignments/default.ron";
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

      environment.etc = {
        "system76-scheduler/config.ron".source = "${cfg.package}/etc/system76-scheduler/config.ron";
        "system76-scheduler/exceptions/default.ron".source = "${cfg.package}/etc/system76-scheduler/exceptions/default.ron";
        "system76-scheduler/assignments/default.ron".text = cfg.assignments;
      };

      environment.systemPackages = [
        (cfg.package)
      ];
    };
}
