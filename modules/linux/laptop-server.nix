{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.laptopServer;
in
{
  options = {
    services.laptopServer = with types; {
      enable = mkEnableOption "laptopServer";
    };
  };

  config = mkIf cfg.enable {
    services.logind.lidSwitchExternalPower = "ignore";
    boot.kernelParams = [ "consoleblank=60" ];
  };
}
