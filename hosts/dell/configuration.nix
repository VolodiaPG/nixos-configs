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
    (with inputs; [
      determinate.nixosModules.default
      agenix.nixosModules.default
      laputil.nixosModules.default
      impermanence.nixosModules.impermanence
      catppuccin.nixosModules.catppuccin
      nixarr.nixosModules.default
    ])
    (with outputs.nixosModules; [
      (common-nix { inherit pkgs user lib; })
      kernel
      intel
      nvidia
      virt
      impermanence
      vpn
      laptop-server
      arr
      # (home-lab { inherit pkgs user config; })
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-intel-cpu-only
      common-gpu-intel
      common-pc
      common-pc-laptop
      common-pc-laptop-ssd
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
      "nouveau"
      "iTCO_wdt"
    ];
  };

  networking = {
    hostId = "30249675";
    hostName = "dell";
    networkmanager.enable = true;
  };

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
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };

  system.stateVersion = "22.05";
}
