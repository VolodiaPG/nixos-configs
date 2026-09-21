# m1 — MacBook running Asahi/NixOS (aarch64), Hyprland desktop.
{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.default
    inputs.determinate.nixosModules.default
    inputs.nixos-apple-silicon.nixosModules.default
  ];

  # Options defined by this repo (modules/nixos/*.nix).
  my = {
    # Core system
    base.enable = true;
    nixSettings.enable = true;
    wm = {
      enable = true;
      gnome.enable = false;
      hyprland.enable = true;
    };

    # Hardware
    ananicy.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    elegantBoot.enable = true;
    virtualization = {
      enable = true;
      libvirt.enable = false;
      containers.enable = true;
    };

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "/dev/disk/by-label/root";
    };
    networking.enable = false;
    vpn.enable = true;

    homeLab.enable = true;
  };

  # Upstream NixOS options.
  services = {
    caddy.enable = false;
    blocky.enable = false;
  };

  # The M1 has 4 E-cores (0-3) and 4 P-cores (4-7). Keep system services off the
  # P-cores, but let the nix daemon use everything.
  systemd = {
    slices = {
      "allcore.slice".sliceConfig = {
        AllowedCPUs = "0-7";
        CPUWeight = 50; # Not that important
      };
      "system".sliceConfig = {
        AllowedCPUs = "0-3"; # E-cores
      };
    };
    services.nix-daemon.serviceConfig = {
      Slice = "allcore.slice";
    };
  };
}
