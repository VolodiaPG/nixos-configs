{
  config,
  lib,
  ...
}:
let
  cfg = config.ollama;
  inherit (lib) mkEnableOption mkIf;
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
