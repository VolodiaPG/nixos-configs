{
  flake,
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
    (with self.nixosModules; [
      common-nix
      desktop
      kernel
      hifi
      hyperhdr
      intel
      nvidia
      impermanence
      elegant-boot
      vpn
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-intel
      common-gpu-nvidia
      common-pc
      common-pc-ssd
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
        gfxmodeEfi = "3440x1440";
      };
    };
    blacklistedKernelModules = [
      "nouveau"
      "iTCO_wdt"
    ];
  };

  networking = {
    hostId = "30249671";
    hostName = "msi";
    networkmanager.enable = true;
  };

  services = {
    desktop.enable = true;
    kernel.enable = true;
    hifi.enable = true;
    hyperhdr.enable = false;
    intel.enable = true;
    nvidia.enable = true;
    impermanence = {
      enable = true;
      rootVolume = "disk/by-label/root";
    };
    elegantBoot.enable = true;
    vpn.enable = true;

    undervolt = {
      enable = true;
      coreOffset = -95;
      gpuOffset = -95;
      uncoreOffset = -95;
      analogioOffset = -95;
    };

    # nvfancontrol = {
    #   enable = true;
    #   configuration = ''
    #     [[gpu]]
    #     id = 0
    #
    #     points = [
    #         [50,0],
    #         [54,0],
    #         [57,46],
    #         [62,62],
    #         [66,75],
    #         [75,85],
    #         [80,100],
    #     ]
    #   '';
    #   cliArgs = "-d -f -l 0";
    # };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    nvidia.prime.offload.enable = false;
  };

  environment = {
    etc = {
      "X11/Xwrapper.config".text = ''
        allowed_users=anybody
        needs_root_rights=yes
      '';
      "X11/xorg.conf".text = lib.mkForce (builtins.readFile ./xorg.conf);
    };
    sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
    };
  };

  system.stateVersion = "22.05";
}
