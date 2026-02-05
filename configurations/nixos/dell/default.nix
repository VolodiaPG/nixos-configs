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
      ./home.nix
      (self + "/secrets/nixos.nix")
    ]
    (with inputs; [
      agenix.nixosModules.default
      # laputil.nixosModules.default
      impermanence.nixosModules.impermanence
      catppuccin.nixosModules.catppuccin
      nixarr.nixosModules.default
      agenix.nixosModules.default
    ])
    (with self.nixosModules; [
      common-nix-settings
      common-overlays
      base
      kernel
      intel
      nvidia
      virt
      impermanence
      vpn
      laptop-server
      # arr
      nix-cache-proxy
      caddy
      home-lab
      backlight-off
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-intel-cpu-only
      common-gpu-intel
      common-pc
      common-pc-laptop
      common-pc-laptop-ssd
    ])
  ];

  services = {
    kernel.enable = true;
    intel.enable = true;
    nvidia.enable = true;
    virt.enable = true;
    impermanence = {
      enable = true;
      rootVolume = "nvme0n1p11";
    };
    vpn.enable = true;
    laptopServer.enable = true;
    backlightOff.enable = true;
  };
}
