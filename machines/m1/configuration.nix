# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
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
      "nouveau"
      "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
    ];
  };

  zramSwap.enable = true;

  networking = {
    hostId = "30249679";
    hostName = "m1";
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  hardware = {
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
      };
    };
  };

  services = {
    openssh.enable = true;
    # libinput = {
    #   enable = true;
    #   touchpad = {
    #     accelStepScroll = 0.00001;
    #     accelStepMotion = 0.00001;
    #     accelPointsScroll = [
    #       0
    #       0.0001
    #       0.00024
    #       0.00025
    #     ];
    #     accelPointsMotion = [
    #       0
    #       0.0001
    #       0.00024
    #       0.00025
    #     ];
    #     # accelStepMotion = 0.001;
    #     tapping = true;
    #     scrollMethod = "twofinger";
    #     naturalScrolling = true;
    #     accelProfile = "flat";
    #     disableWhileTyping = true;
    #   };
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
