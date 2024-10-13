# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        #    version = 2;
        device = "nodev";
        efiSupport = true;
        #    enableCryptodisk = true;
      };
    };
    blacklistedKernelModules = [
      "nouveau"
      "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
    ];
  };

  zramSwap.enable = true;

  services.logind.extraConfig = ''
    # don't shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';

  networking = {
    hostId = "30249679";
    hostName = "m1";
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  hardware.asahi = {
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "replace";
    setupAsahiSound = true;
  };

  services = {
    openssh.enable = true;

    # Enable the X11 windowing system.
    # xserver = {
    #   enable = true;
    #   #  videoDrivers = ["nvidia"];
    #   #  exportConfiguration = true;
    # };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
