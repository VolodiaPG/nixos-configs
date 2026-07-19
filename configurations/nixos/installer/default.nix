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
      exec disko-install --flake "$FLAKE"#"$TARGET" --disk main "$DISK"
    '')
  ];

  # ponytail: impermanence mounts /dev/root_vg at boot — won't exist in installer
  services = {
    impermanence.enable = false;
    base.enable = true;
  };

  isoImage = {
    volumeID = "NIXOS_INSTALLER";
    makeUsbBootable = true;
    makeEfiBootable = true;
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
