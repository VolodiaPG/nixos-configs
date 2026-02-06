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
    self.nixosModules.all-modules
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-cpu-intel-cpu-only
    common-pc
    common-pc-ssd
  ])
  ++ (with inputs; [
    srvos.nixosModules.server
    disko.nixosModules.disko
  ]);

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    commonOverlays.enable = true;

    # Hardware and kernel
    kernel.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "sda";
      disko = true;
    };
    vpn.enable = true;
    laptopServer.enable = true;
    backlightOff.enable = true;

    # Media server stack
    arr.enable = true;
    caddy.enable = true;
    samba.enable = true;
  };

  system.stateVersion = "22.05";
}
