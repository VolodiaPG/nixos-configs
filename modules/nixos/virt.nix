{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.virt;
in
{
  options = {
    services.virt = {
      enable = mkEnableOption "virt";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
  };
}
