{
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

  networking = {
    hostId = "30249676";
    hostName = "home-server";
    networkmanager.enable = true;
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    graphics.enable = false;
  };

  system.stateVersion = "22.05";
}
