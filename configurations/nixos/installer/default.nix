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
    ../msi/configuration.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.all-modules
    inputs.disko.nixosModules.disko
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
  ];

  environment.systemPackages = [
    pkgs.gparted-full
  ];

  # ponytail: impermanence mounts /dev/root_vg at boot — won't exist in installer
  services = {
    impermanence.enable = false;
    base.enable = true;
  };

  isoImage = {
    volumeID = "NIXOS_INSTALLER";
    makeUsbBootable = true;
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
