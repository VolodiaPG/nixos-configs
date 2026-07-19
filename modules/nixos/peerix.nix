{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  cfg = config.services.peerix;
in
{
  options = {
    services.peerix = {
      enable = mkEnableOption "peerix";

      extraHosts = mkOption {
        description = "Hosts to consider";
        type = lib.types.listOf lib.types.str;
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
