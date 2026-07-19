{ config, lib, ... }:
let
  cfg = config.services.syncthing;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    services.syncthing = {
      overrideDevices = false;
      overrideFolders = false;
      guiAddress = "0.0.0.0:8384";
      extraOptions = [
        "--allow-newer-config"
      ];
    };
  };
}
