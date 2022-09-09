{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/zfs.nix
      ../../modules/common.nix
      ../../modules/desktop.nix
      ../../modules/gaming.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 6;

  # Use XanMod kernel w/ a bunch of optimizations
  boot.kernelPackages = pkgs.linuxPackages_xanmod;
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

  # services.fail2ban = {
  #   enable = true;
  #   maxretry = 5;
  #   ignoreIP = [
  #     "127.0.0.0/8"
  #     "10.0.0.0/8"
  #     "172.16.0.0/12"
  #     "192.168.0.0/16"
  #   ];
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
