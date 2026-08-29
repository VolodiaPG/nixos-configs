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
  ];

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    # nixCacheProxy.enable = true;
    wm = {
      enable = true;
      # gnome.enable = true;
      hyprland = {
        enable = true;
      };
    };

    # Hardware and kernel
    kernel = {
      enable = true;
      lowLatencyNetworking = true;
      cachyDesktop = true;
    };

    nvidia.enable = true;

    hyperhdr.enable = true;
    myAnanicy.enable = true;
    virtualization = {
      enable = true;
      libvirt.enable = false;
      containers.enable = true;
    };
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    caddy.enable = true;
    homeLab.enable = false;
    gaming.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "/dev/sda";
      disko = true;
    };
    networking.enable = false;
    vpn.enable = true;

    # From nixos
    # blueman.enable = true;
    blocky.enable = false;

    immich-ml = {
      enable = false;
    };
  };
}
