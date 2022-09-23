{ config, pkgs, ... }:
{
  imports =
    [
      ../../services/nbfc-linux/nbfc-linux.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };


  # Use XanMod kernel w/ a bunch of optimizations
  # boot.kernelPackages = pkgs.linuxPackages_xanmod;
  # boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  # boot.kernelPackages = pkgs.callPackage ../../pkgs/linux-xanmod-volodiapg { };
  boot.kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage ../../pkgs/linux-xanmod-volodiapg { }));
  boot.kernelParams = [
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "tsx=on"
    "tsx_async_abort=off"
    "mitigations=off"
  ];

  networking = {
    hostId = "30249670";
    hostName = "ux430ua-nixos";
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # programs.mosh.enable = true;
  # programs.mosh.withUtempter = true;

  services.undervolt = {
    enable = true;
    gpuOffset = -95;
    uncoreOffset = -95;
    coreOffset = -95;
  };

  hardware.cpu.intel.updateMicrocode = true;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      # intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services.peerix = {
    enable = true;
    package = pkgs.peerix;
    user = "volodia";
    group = "users";
    openFirewall = true; # UDP/12304
    privateKeyFile = ../../secrets/peerix-ux430ua-private;
    publicKeyFile = ../../secrets/peerix-ux430ua-public;
    publicKey = "peerix-msi-nixos:o9VMop4zgalELlIUmJXzF3GgIUQj2rqvPjMo3AqTyeo="; # separated by spaces
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
