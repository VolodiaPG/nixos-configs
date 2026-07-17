{
  config,
  lib,
  inputs,
  ...
}:
{
  config.nixos.dell = lib.mkMerge [
    config.nixos.base
    config.nixos.server
    config.nixos.intel
    config.nixos.nvidia
    config.nixos.virt
    config.nixos.caddy
    config.nixos.homeLab
    (
      {
        pkgs,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-cpu-intel-cpu-only
          common-gpu-intel
          common-pc
          common-pc-laptop
          common-pc-laptop-ssd
        ]);

        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "22.05";

        networking = {
          hostId = "30249675";
          hostName = "dell";
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
          initrd.availableKernelModules = [
            "xhci_pci"
            "thunderbolt"
            "ahci"
            "nvme"
            "usb_storage"
            "sd_mod"
            "sdhci_pci"
          ];
          kernelModules = [ "kvm-intel" ];
          kernelParams = [ "usbcore.autosuspend=-1" ];
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/D83C-1680";
          fsType = "vfat";
        };

        swapDevices = [
          {
            device = "/dev/disk/by-uuid/7309ec42-f066-404c-a948-d09765bf67a4";
            options = [ "noatime" ];
          }
        ];

        powerManagement.cpuFreqGovernor = lib.mkDefault "conservative";

        nixpkgs.config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
        };

        hardware = {
          cpu.intel.updateMicrocode = true;
          graphics = {
            enable = true;
            extraPackages = with pkgs; [
              intel-media-driver
              libva-vdpau-driver
              libvdpau-va-gl
            ];
          };
        };

        services.impermanence.rootVolume = "nvme0n1p11";
      }
    )
  ];

  config.home.dell = lib.mkMerge [
    config.home.base
    config.home.server
    (_: { home.stateVersion = "22.05"; })
  ];
}
