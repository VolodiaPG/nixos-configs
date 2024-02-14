{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.qbittorent;
in {
  options = {
    services.qbittorent = with types; {
      enable = mkEnableOption "qbittorent";

      port = mkOption {
        description = "webui port";
        type = types.str;
        default = "60080";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.qbittorrent = mkIf cfg.zfsTweaks {
      description = "Qbittorrent web";

      wantedBy = ["multi-user.target" "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui ${cfg.port}";
        ConditionPathIsDirectory = "/private/data";
      };
    };
  };
}
