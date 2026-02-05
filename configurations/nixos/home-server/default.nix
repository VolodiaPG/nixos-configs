{ flake, lib, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = lib.flatten [
    [
      ./configuration.nix
      ./hardware-configuration.nix
      ./disk.nix
      ./home.nix
      (self + "/secrets/nixos.nix")
    ]
    (with self.nixosModules; [
      common-nix-settings
      common-overlays
      base
      kernel
      impermanence
      vpn
      laptop-server
      recyclarr
      arr
      samba
      caddy
      backlight-off
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-intel
      common-cpu-intel-cpu-only
      common-pc
      common-pc-ssd
    ])
    (with inputs; [
      srvos.nixosModules.server
      disko.nixosModules.disko
      nixarr.nixosModules.default
      agenix.nixosModules.default
      impermanence.nixosModules.impermanence
    ])
  ];

  services = {
    kernel.enable = true;
    impermanence = {
      enable = true;
      rootVolume = "sda";
      disko = true;
    };
    vpn.enable = true;
    laptopServer.enable = true;
    backlightOff.enable = true;
  };

  system.stateVersion = "22.05";
}
