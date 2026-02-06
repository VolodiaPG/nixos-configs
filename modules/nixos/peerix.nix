{ config, lib, ... }:
with lib;
let
  cfg = config.services.peerix;
in
{
  options = {
    services.peerix = with types; {
      enable = mkEnableOption "peerix";

      extraHosts = mkOption {
        description = "Hosts to consider";
        type = types.listOf types.str;
        default = [
          "asus"
          "msi"
          "dell"
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.peerix = {
        isSystemUser = true;
        group = "peerix";
      };
      groups.peerix = { };
    };
  };
}
