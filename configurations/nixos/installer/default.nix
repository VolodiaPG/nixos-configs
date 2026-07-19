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
    pkgs.gum
    pkgs.jq
    pkgs.disko
    (pkgs.writeShellScriptBin "xdisko" ''
      set -euo pipefail

      FLAKE="github:volodiapg/nixos-configs"

      TARGET=$(
        nix flake show "$FLAKE" --json 2>/dev/null \
          | jq -r '.["inventory"]["nixosConfigurations"]["output"]["children"] | keys[] | select(. != "installer")' \
          | gum choose --header "Select which configuration to install:"
      )

      BLOCKDEV=$(
        lsblk --json 2>/dev/null \
          | jq -r '.["blockdevices"].[] | "\(.name) (\(.size))"' \
          | gum choose --header "Select disk to erase and install nixos on:" \
          | awk -F ' ' '{print $1}'
      )
      DISK="/dev/$BLOCKDEV"

      gum confirm --default=false "This will erase $DISK to install $TARGET, confirm:"

      echo selected "$FLAKE"#"$TARGET"
      # exec disko-install --flake "$FLAKE"#"$TARGET" --disk main "$DISK"
      sudo disko --mode disko --flake "$FLAKE"#"$TARGET" --disk main "$DISK"
      sudo nixos-install --no-channel-copy --no-root-password --flake "$FLAKE"#"$TARGET"
    '')
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
