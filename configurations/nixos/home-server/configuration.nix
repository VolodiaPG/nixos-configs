{ lib, ... }: {
  # Host-specific configuration
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
      "iTCO_wdt"
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking = {
    hostId = "30249676";
    hostName = "home-server";
    wireless.enable = lib.mkForce false;
    networkmanager.enable = true;
  };

  hardware = {
    graphics.enable = false;
  };

  system.stateVersion = "22.05";
}
