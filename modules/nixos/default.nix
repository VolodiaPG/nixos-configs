# Aggregator for the NixOS modules in this directory. Imported by every host as
# `self.nixosModules.default`; importing it only *declares* the `my.*` options —
# each module is inert until its `enable` is set by a host.
#
# Home Manager is wired separately, in ./home-manager.nix.
{
  imports = [
    ./ananicy.nix
    ./arr.nix
    ./backlight-off.nix
    ./backup.nix
    ./base.nix
    ./betterSleep.nix
    ./caddy.nix
    ./common-nix-settings.nix
    ./common-overlays.nix
    ./desktop.nix
    ./elegant-boot.nix
    ./gaming.nix
    ./gnome.nix
    ./hifi.nix
    ./home-lab.nix
    ./hyperhdr.nix
    ./hyprland.nix
    ./immich-ml.nix
    ./immich.nix
    ./impermanence.nix
    ./kernel.nix
    ./kubernetes.nix
    ./laptop-server.nix
    ./networking.nix
    ./nvidia.nix
    ./recyclarr.nix
    ./samba.nix
    ./version.nix
    ./virtualization.nix
    ./vpn.nix
  ];
}
