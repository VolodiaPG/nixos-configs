{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.virtualization;
in
{
  options = {
    my.virtualization = {
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
        virtualisation = {
          oci-containers.backend = "docker";
          docker = {
            enable = true;
            # overlay2 is the default and works on ext4/xfs; btrfs benefits from
            # its native storage driver when the root volume is btrfs.
            extraOptions =
              (lib.optionalString (
                config.my.impermanence.enable && config.my.impermanence.fsType == "btrfs"
              ) "--storage-driver btrfs ")
              + "--exec-opt native.cgroupdriver=systemd --bip=192.168.234.1/24";
            autoPrune = {
              enable = true;
              dates = "weekly";
            };
          };
        };

        environment.systemPackages = [ pkgs.docker-compose ];
      })
    ]
  );
}
