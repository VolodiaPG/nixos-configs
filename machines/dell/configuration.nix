# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };
  boot.blacklistedKernelModules = [
    "nouveau"
    "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
  ];

  networking = {
    hostId = "30249675";
    hostName = "dell";
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  services.openssh.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    videoDrivers = [ "nvidia" ];
    exportConfiguration = true;
  };
  hardware.nvidia = {
    powerManagement.enable = true;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    nvidiaSettings = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

