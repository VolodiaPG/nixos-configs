{
  flake,
  pkgs,
  lib,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;

  # # ponytail: embed every config except installer so ISO can install offline
  # targets = lib.filterAttrs (n: _: n == "msi") self.nixosConfigurations;
  # perConfig = _: cfg: [
  #   cfg.config.system.build.toplevel
  #   cfg.config.system.build.diskoScript
  #   cfg.config.system.build.diskoScript.drvPath
  #   cfg.pkgs.stdenv.drvPath
  #   cfg.pkgs.perlPackages.ConfigIniFiles
  #   cfg.pkgs.perlPackages.FileSlurp
  #   (cfg.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
  # ];
in
{
  imports = [
    ../msi/configuration.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.all-modules
    inputs.disko.nixosModules.disko
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # environment.etc."install-closure".source =
  #   "${pkgs.closureInfo { rootPaths = lib.concatLists (lib.mapAttrsToList perConfig targets); }}/store-paths";

  environment.systemPackages = [
    pkgs.gparted-full
    pkgs.bash
    pkgs.git
    pkgs.xinstall
  ];

  # ponytail: impermanence mounts /dev/root_vg at boot — won't exist in installer
  services = {
    impermanence.enable = false;
    base.enable = true;

    getty.autologinUser = "nixos";
  };

  users.users.nixos = {
    initialPassword = lib.mkForce "";
    password = lib.mkForce null;
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
