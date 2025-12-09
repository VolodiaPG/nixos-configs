{
  inputs,
  outputs,
  user,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (with outputs.nixosModules; [
      common-nix
      kernel
      impermanence
      vpn
      laptop-server
      recyclarr
      arr
      samba
      caddy
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
    ])
    (import ./home.nix {
      inherit
        inputs
        outputs
        user
        pkgs
        lib
        ;
    })
    ./hardware-configuration.nix
    ./disk.nix
  ];

  # Host-specific configuration
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };
    blacklistedKernelModules = [
      "iTCO_wdt"
    ];
  };

  networking = {
    hostId = "30249676";
    hostName = "home-server";
    networkmanager.enable = true;
  };

  services = {
    kernel.enable = true;
    impermanence = {
      enable = true;
      rootVolume = "sda";
      disko = true;
    };
    vpn.enable = true;
    laptopServer.enable = true;
  };

  _module.args.disks = [ "/dev/sda" ];

  hardware = {
    cpu.intel.updateMicrocode = true;
    graphics.enable = false;
  };

  system.stateVersion = "22.05";
}
