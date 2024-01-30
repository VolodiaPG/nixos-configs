{
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
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
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    mountpoint = "/";
                  };
                  # Subvolume name is the same as the mountpoint
                  "/nix" = {
                    mountOptions = ["ssd" "compress-force=zstd:9" "noatime" "discard=async" "space_cache=v2" "autodefrag"];
                    mountpoint = "/nix";
                  };
                  # Parent is not mounted so the mountpoint must be set
                  "/persistent" = {
                    mountOptions = ["ssd" "compress-force=zstd:9" "noatime" "discard=async" "space_cache=v2" "autodefrag"];
                    mountpoint = "/persistent";
                  };

                  "/private" = {
                    mountOptions = ["ssd" "compress-force=zstd:15" "noatime" "discard=async" "space_cache=v2" "autodefrag"];
                    mountpoint = "/private";
                  };
                };
              };
            };

            # mountpoint = "/root";
            plainSwap = {
              size = "8G";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
  };
}
