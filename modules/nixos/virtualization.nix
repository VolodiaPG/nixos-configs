{
  config,
  lib,
  ...
}:
let
  cfg = config.services.virtualization;
in
{
  options = {
    services.virtualization = {
      enable = lib.mkEnableOption "virtualization";
      libvirt.enable = lib.mkEnableOption "libvirt";
      containers.enable = lib.mkEnableOption "Docker containers";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.libvirt.enable {
        virtualisation.libvirtd.enable = true;
      })
      (lib.mkIf cfg.containers.enable {
        virtualisation.docker.enable = true;
        virtualisation.oci-containers.backend = "docker";
      })
    ]
  );
}
