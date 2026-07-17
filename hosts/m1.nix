{
  config,
  lib,
  inputs,
  ...
}:
{
  config.nixos.m1 = lib.mkMerge [
    config.nixos.base
    config.nixos.desktop
    config.nixos.niri
    config.nixos.virt
    config.nixos.asahi
    config.nixos.homeLab
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
          common-pc
          common-pc-laptop
          common-pc-laptop-ssd
        ]);

        nixpkgs.hostPlatform = "aarch64-linux";
        system.stateVersion = "22.05";

        networking = {
          hostId = "30249679";
          hostName = "m1";
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
            "nvme"
            "usb_storage"
            "sdhci_pci"
          ];
          kernelParams = [ "usbcore.autosuspend=-1" ];
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
        };

        powerManagement.cpuFreqGovernor = lib.mkForce "schedutil";

        hardware = {
          enableRedistributableFirmware = true;
          bluetooth = {
            enable = true;
            powerOnBoot = true;
            settings = {
              General = {
                FastConnectable = true;
                JustWorksRepairing = "always";
                Experimental = true;
              };
              LE = {
                MinConnectionInterval = 6;
                MaxConnectionInterval = 9;
                ConnectionLatency = 0;
              };
              Policy = {
                AutoEnable = true;
                ReconnectAttempts = 7;
                ReconnectIntervals = "1,2,4,8,16,32,64";
              };
            };
          };
          asahi = {
            enable = true;
            setupAsahiSound = true;
            peripheralFirmwareDirectory = ./firmware;
          };
          apple.touchBar = {
            enable = true;
            settings = {
              MediaLayerDefault = true;
              ShowButtonOutlines = false;
              AdaptiveBrightness = true;
              ActiveBrightness = 128;
              MediaLayerKeys = [
                {
                  Icon = "brightness_low";
                  Action = "BrightnessDown";
                }
                {
                  Icon = "brightness_high";
                  Action = "BrightnessUp";
                }
                {
                  Icon = "mic_off";
                  Action = "MicMute";
                }
                {
                  Icon = "backlight_low";
                  Action = "IllumDown";
                }
                {
                  Icon = "backlight_high";
                  Action = "IllumUp";
                }
                {
                  Icon = "fast_rewind";
                  Action = "PreviousSong";
                }
                {
                  Icon = "play_pause";
                  Action = "PlayPause";
                }
                {
                  Icon = "fast_forward";
                  Action = "NextSong";
                }
                {
                  Icon = "volume_off";
                  Action = "Mute";
                }
                {
                  Icon = "volume_down";
                  Action = "VolumeDown";
                }
                {
                  Icon = "volume_up";
                  Action = "VolumeUp";
                }
              ];
            };
          };
        };

        services.impermanence.rootVolume = "disk/by-label/root";

        systemd = {
          slices = {
            "allcore.slice".sliceConfig = {
              AllowedCPUs = "0-7";
              CPUWeight = 50;
            };
            "system".sliceConfig = {
              AllowedCPUs = "0-3";
            };
          };
          services.nix-daemon.serviceConfig = {
            Slice = "allcore.slice";
          };
        };
      }
    )
  ];

  config.home.m1 = lib.mkMerge [
    config.home.base
    config.home.desktop
    config.home.niri
    (_: {
      home.stateVersion = "22.05";
      programs.kitty.font.size = 12;
    })
  ];
}
