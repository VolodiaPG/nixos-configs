{
  flake,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (flake) inputs;
  inherit (inputs) self;
  inherit (flake.config) user;
in
{
  imports = lib.flatten [
    (with inputs; [
      agenix.nixosModules.default
      # laputil.nixosModules.default
      impermanence.nixosModules.impermanence
      catppuccin.nixosModules.catppuccin
      nixarr.nixosModules.default
    ])
    (with self.commonModules; [
      common-nix-settings
    ])
    (with self.nixosModules; [
      common-nix
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
      # home-lab
      (home-lab { inherit user config; })
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
        self
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
