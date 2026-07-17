{
  config,
  lib,
  inputs,
  ...
}:
{
  config.nixos.msi = lib.mkMerge [
    config.nixos.base
    config.nixos.desktop
    config.nixos.gnome
    config.nixos.intel
    config.nixos.nvidia
    config.nixos.virt
    config.nixos.caddy
    config.nixos.immich-ml
    (
      {
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-cpu-intel
          common-gpu-nvidia
          common-pc-ssd
        ]);

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "22.05";

        networking = {
          hostId = "30249671";
          hostName = "msi";
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
          blacklistedKernelModules = [
            "nouveau"
            "iTCO_wdt"
          ];
          initrd = {
            availableKernelModules = [
              "xhci_pci"
              "ehci_pci"
              "ahci"
              "usbhid"
              "usb_storage"
              "sd_mod"
            ];
            kernelModules = [ "dm-snapshot" ];
          };
          kernelParams = [
            "usbcore.autosuspend=-1"
            "mitigations=off"
          ];
          kernelModules = [ "kvm-intel" ];
          resumeDevice = "/dev/disk/by-label/swap";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
        };

        swapDevices = [
          {
            device = "/dev/disk/by-label/swap";
            options = [ "noatime" ];
          }
        ];

        powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

        hardware.cpu.intel.updateMicrocode = true;

        services.impermanence.rootVolume = "disk/by-label/root";
        services.kernel.latestKernel = true;
      }
    )
  ];

  config.home.msi = lib.mkMerge [
    config.home.base
    config.home.desktop
    config.home.gnome
    (_: { home.stateVersion = "22.05"; })
  ];
}
