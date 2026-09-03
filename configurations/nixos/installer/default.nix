{
  flake,
  pkgs,
  lib,
  modulesPath,
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
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.determinate.nixosModules.default
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking = {
    # hostId = "30239671";
    hostName = "installer";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    networkmanager.enable = true;
  };

  services.envfs.enable = true;

  environment.systemPackages = [
    pkgs.coreutils
    pkgs.bash
    pkgs.git
    pkgs.nix
    # ponytail: thin wrappers — the real scripts come from the flake via nix run,
    # so the ISO stays small and always runs the latest version.
    (pkgs.writeShellScriptBin "xinstall" ''
      exec nix run github:volodiapg/nixos-configs#xinstall -- "$@"
    '')
    (pkgs.writeShellScriptBin "xmount" ''
      exec nix run github:volodiapg/nixos-configs#xmount -- "$@"
    '')
  ];

  # ponytail: impermanence mounts rootVolume at boot — won't exist in installer
  services = {
    impermanence.enable = false;
    base.enable = true;
    commonNixSettings.enable = true;

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
