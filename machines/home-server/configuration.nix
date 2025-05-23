{
  # Use the systemd-boot EFI boot loader.

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        #    enableCryptodisk = true;
      };
    };
    blacklistedKernelModules = [
      "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
    ];
  };

  networking = {
    hostId = "30249676";
    hostName = "home-server";
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics = {
    enable = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
