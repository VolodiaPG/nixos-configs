{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.mypeerix;
in {
  options = {
    services.mypeerix = with types; {
      enable = mkEnableOption "mypeerix";

      extraHosts = mkOption {
        description = "Hosts to consider";
        type = listOf types.str;
        default = ["asus" "msi" "dell"];
      };
    };
  };

  config = mkIf cfg.enable {
    services.peerix = {
      enable = true;
      openFirewall = true; # UDP/12304
      privateKeyFile = ../secrets/peerix-private;
      publicKeyFile = ../secrets/peerix-public;
      user = "peerix";
      group = "peerix";
      disableBroadcast = true;
      inherit (cfg) extraHosts; # hostnames
    };
    users = {
      users.peerix = {
        isSystemUser = true;
        group = "peerix";
      };
      groups.peerix = {};
    };
  };
}
