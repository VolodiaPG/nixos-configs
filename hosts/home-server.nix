{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (config) me;
in
{
  config.nixos.home-server = lib.mkMerge [
    config.nixos.base
    config.nixos.server
    config.nixos.intel
    config.nixos.caddy
    config.nixos.samba
    config.nixos.immich
    config.nixos.homeLab
    config.nixos.backup
    config.nixos.networking
    (
      {
        lib,
        config,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
          inputs.srvos.nixosModules.server
          inputs.disko.nixosModules.disko
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-cpu-intel
          common-cpu-intel-cpu-only
          common-pc
          common-pc-ssd
        ]);

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "22.05";

        networking = {
          hostId = "30249676";
          hostName = "home-server";
          networkmanager.enable = true;
        };

        boot = {
          loader = {
            efi.canTouchEfiVariables = true;
            grub = {
              enable = true;
              device = "nodev";
              efiSupport = true;
            };
          };
          blacklistedKernelModules = [ "iTCO_wdt" ];
          initrd = {
            availableKernelModules = [
              "xhci_pci"
              "ahci"
              "usb_storage"
              "sd_mod"
              "rtsx_pci_sdmmc"
            ];
            kernelModules = [ "dm-snapshot" ];
          };
          kernelModules = [ "kvm-intel" ];
          kernelParams = [ "mitigations=off" ];
        };

        fileSystems."/data" = {
          device = "/dev/disk/by-uuid/9e5f9d10-25ce-85f8-cbfe-d5aefabdef97";
          fsType = "ext4";
        };

        powerManagement.cpuFreqGovernor = lib.mkDefault "conservative";

        hardware = {
          cpu.intel.updateMicrocode = true;
          graphics.enable = false;
          bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
        };

        services.impermanence = {
          rootVolume = "sda";
          disko = true;
        };

        services.backup = {
          paths = [
            "/data/syncthing"
            "/data/immich"
            "/home/${me.username}/Documents"
          ];
          user = me.hetzner-user;
          password = config.age.secrets.hetzner-token.path;
          subuser = "sub1";
        };

        disko.devices.disk.sda = {
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
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                    };
                    "/nix" = {
                      mountOptions = [
                        "ssd"
                        "compress=zstd:2"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                        "autodefrag"
                      ];
                      mountpoint = "/nix";
                    };
                    "/persistent" = {
                      mountOptions = [
                        "ssd"
                        "compress=zstd:3"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                        "autodefrag"
                      ];
                      mountpoint = "/persistent";
                    };
                    "/private" = {
                      mountOptions = [
                        "ssd"
                        "compress=zstd:3"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                        "autodefrag"
                      ];
                      mountpoint = "/private";
                    };
                  };
                };
              };
              plainSwap = {
                size = "8G";
                content = {
                  type = "swap";
                };
              };
            };
          };
        };
      }
    )
  ];

  config.home.home-server = lib.mkMerge [
    config.home.base
    config.home.server
    (_: { home.stateVersion = "22.05"; })
  ];
}
