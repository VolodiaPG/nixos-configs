{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.ollama;
in
{
  options = {
    ollama = {
      enable = mkEnableOption "ollama configuration";
    };
  };
  config = mkIf cfg.enable {
    services.ollama = {
      enable = false;
    };
  };
}
