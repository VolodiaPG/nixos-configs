{
  config,
  lib,
  ...
}:
let
  cfg = config.services.my_virtualization;
in
{

  options = {
    services.my_virtualization = {
      enable = lib.mkEnableOption "Virtulization settings";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
  };
}
