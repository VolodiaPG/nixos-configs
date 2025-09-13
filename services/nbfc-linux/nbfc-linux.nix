{ pkgs, ... }:
{
  systemd.services.nbfc-linux =
    let
      cfg = pkgs.writeText "nbfc.json" (
        builtins.toJSON {
          # SelectedConfigId = "Asus UX430UA Volodia";
          SelectedConfigId = "Asus Zenbook UX430UA";
          EmbeddedControllerType = "ec_sys_linux";
        }
      );
    in
    {
      description = "NBFC-Linux";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.kmod ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${(pkgs.callPackage ../../pkgs/nbfc-linux { })}/bin/nbfc_service -c ${cfg}";
        TimeoutStopSec = "5";
      };
    };
}
