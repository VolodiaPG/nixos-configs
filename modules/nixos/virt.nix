{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.virt;
in
{
  options = {
    services.virt = with types; {
      enable = mkEnableOption "virt";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
  };
}
