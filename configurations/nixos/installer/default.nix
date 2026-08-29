{
  flake,
  pkgs,
  lib,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.default
    inputs.disko.nixosModules.disko
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking = {
    hostName = "installer";
    networkmanager.enable = true;
  };

  environment.systemPackages = [
    pkgs.gparted-full
    pkgs.bash
    pkgs.git
    pkgs.xinstall
    pkgs.xmount
  ];

  # ponytail: impermanence mounts rootVolume at boot — won't exist in installer
  services = {
    impermanence.enable = false;
    base.enable = true;

    getty.autologinUser = "nixos";
  };

  users.users.nixos = {
    initialPassword = lib.mkForce "nixos";
    password = lib.mkForce "nixos";
    hashedPassword = lib.mkForce null;
    hashedPasswordFile = lib.mkForce null;
    initialHashedPassword = lib.mkForce null;
    extraGroups = [ "wheel" ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  isoImage = {
    volumeID = "NIXOS_INSTALLER";
    makeUsbBootable = true;
    makeEfiBootable = true;
    includeSystemBuildDependencies = false;
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
  };

  networking.wireless.enable = lib.mkForce true;

  # ponytail: installer needs the filesystems disko will lay down
  boot.supportedFilesystems = [
    "btrfs"
    "ext4"
    "vfat"
    "xfs"
    "zfs"
  ];

  system.stateVersion = "22.05";
}
