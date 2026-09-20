# msi — desktop/workstation: NVIDIA + CUDA, Hyprland, gaming, HyperHDR.
{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./disk.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.determinate.nixosModules.default
  ];

  # Options defined by this repo (modules/nixos/*.nix).
  my = {
    # Core system
    base.enable = true;
    nixSettings.enable = true;
    wm = {
      enable = true;
      hyprland.enable = true;
      # gnome.enable = true;
    };

    # Hardware and kernel
    kernel = {
      enable = true;
      lowLatencyNetworking = true;
      cachyDesktop = true;
    };
    nvidia.enable = true;
    hyperhdr.enable = true;
    ananicy.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    elegantBoot.enable = false;

    virtualization = {
      enable = true;
      libvirt.enable = false;
      containers.enable = true;
    };

    # Storage and networking
    impermanence = {
      enable = true;
      fsType = "ext4";
      rootVolume = "/dev/disk/by-label/root";
      disko = true;
    };
    networking.enable = false;
    vpn.enable = true;

    gaming.enable = true;
    homeLab.enable = false;
    immich-ml.enable = false;
  };

  # Upstream NixOS options. `caddy` is also extended by modules/nixos/caddy.nix,
  # which keys off this upstream `enable` flag.
  services = {
    caddy.enable = true;
    blocky.enable = false;
  };
}
