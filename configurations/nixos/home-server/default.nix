{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.nixosModules.default
    ./configuration.nix
    inputs.srvos.nixosModules.server
    inputs.disko.nixosModules.disko
    inputs.nixarr.nixosModules.default
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "home-server";
  networking.hostId = "30249676";

  services = {
    kernel.enable = true;
    impermanence.enable = true;
    vpn.enable = true;
    laptopServer.enable = true;
  };

  hardware.graphics.enable = false;

  _module.args.disks = [ "/dev/sda" ];

  system.stateVersion = "22.05";
}
