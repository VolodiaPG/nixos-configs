{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../services/nvfancontrol/nvfancontrol.nix
  ];
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        #enableCryptodisk = true;
      };
    };
    blacklistedKernelModules = [
      "nouveau"
      "iTCO_wdt" # iTCO_wdt module sometimes block kernel.nmi_watchdog = 0
    ];
  };

  networking = {
    hostId = "30249671";
    hostName = "msi";
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  # programs.xwayland.enable = true;
  # services.xserver.displayManager.gdm.wayland = true;

  services = {
    openssh.enable = true;

    undervolt = {
      enable = true;
      coreOffset = -95;
      gpuOffset = -95;
      uncoreOffset = -95;
      analogioOffset = -95;
    };

    # Enable the X11 windowing system.
    #xserver = {
    #  videoDrivers = ["nvidia"];
    #  exportConfiguration = true;
    #};

    nvfancontrol = {
      enable = true;
      configuration = ''
        [[gpu]]
        id = 0

        points = [
            [50,0],
            [54,0],
            [57,46],
            [62,62],
            [66,75],
            [75,85],
            [80,100],
        ]
      '';
      cliArgs = "-d -f -l 0";
    };
  };

  hardware = {
    nvidia = {
      open = true;
      powerManagement.enable = true;
      modesetting.enable = true;
      nvidiaPersistenced = true;
      nvidiaSettings = false;
    };
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        #intel-media-driver # LIBVA_DRIVER_NAME=iHD
        #vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  environment = {
    etc = {
      "X11/Xwrapper.config".text = ''
        allowed_users=anybody
        needs_root_rights=yes
      '';
      "X11/xorg.conf".text = lib.mkForce (builtins.readFile ./xorg.conf);
    };
    systemPackages = with pkgs; [
      # nvtop
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
    };
  };

  #   # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
  hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
