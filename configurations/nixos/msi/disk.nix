{
  # LVM layout: a single PV partition feeds the `root_vg` volume group, which
  # holds resizable ext4 logical volumes for /, /nix and /persistent. Only the
  # root LV is rotated by impermanence each boot; /nix and /persistent persist.
  # Logical volumes can be grown online with `lvextend` + `resize2fs`, so the
  # initial sizes below are not hard limits — `persistent` takes all remaining
  # space (100%FREE) so nothing is wasted at install time.
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_840_EVO_250GB_S1DBNSCFA01973D";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root_pv = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "root_vg";
              };
            };
          };
        };
      };
    };

    lvm_vg.root_vg.lvs = {
      root = {
        size = "16G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
          mountOptions = [ "noatime" ];
          extraArgs = [
            "-L"
            "root"
          ];
        };
      };

      nix = {
        size = "64G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/nix";
          mountOptions = [ "noatime" ];
          extraArgs = [
            "-L"
            "nix"
          ];
        };
      };

      persistent = {
        size = "100%FREE";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/persistent";
          mountOptions = [ "noatime" ];
          extraArgs = [
            "-L"
            "persistent"
          ];
        };
      };
    };
  };

  # Swap lives on the persistent LV (which survives the root rotation) instead
  # of a dedicated swap partition.
  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 16 * 1024;
    }
  ];
}
