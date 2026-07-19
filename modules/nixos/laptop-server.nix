{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.laptopServer;
in
{
  options = {
    services.laptopServer = {
      enable = mkEnableOption "laptopServer";
    };
  };

  config = mkIf cfg.enable {
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    boot.kernelParams = [ "consoleblank=60" ];
  };
}
