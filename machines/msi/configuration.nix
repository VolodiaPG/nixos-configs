{ config, pkgs, ... }:
{
  imports = [ ../../services/nvfancontrol/nvfancontrol.nix ];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
  };

  # Use XanMod kernel w/ a bunch of optimizations
  # boot.kernelPackages = pkgs.linuxPackages_xanmod;
  boot.kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage ../../pkgs/linux-xanmod-volodiapg { }));
  boot.kernelParams = [
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "tsx=on"
    "tsx_async_abort=off"
    "mitigations=off"
  ];

  networking = {
    hostId = "30249671";
    hostName = "msi-nixos";
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  hardware.nvidia.modesetting.enable = true;
  # programs.xwayland.enable = true;
  # services.xserver.displayManager.gdm.wayland = true;

  virtualisation.docker.enableNvidia = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # programs.mosh.enable = true;
  # programs.mosh.withUtempter = true;

  services.undervolt = {
    enable = true;
    coreOffset = -95;
    gpuOffset = -95;
    uncoreOffset = -95;
    analogioOffset = -95;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    videoDrivers = [ "nvidia" ];
    # serverLayoutSection = ''
    #   Identifier     "Layout0"
    #   Screen      0  "Screen0" 0 0
    #   Option         "Xinerama" "0"
    # '';
    # screenSection = ''
    #   Identifier     "Screen0"
    #   Device         "Device0"
    #   Monitor        "Monitor0"
    #   DefaultDepth    24
    #   Option         "Stereo" "0"
    #   Option         "nvidiaXineramaInfoOrder" "DFP-2"
    #   Option         "metamodes" "3440x1440_120 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
    #   Option         "SLI" "Off"
    #   Option         "MultiGPU" "Off"
    #   Option         "BaseMosaic" "off"
    #   SubSection     "Display"
    #       Depth       24
    #   EndSubSection
    # '';
    # deviceSection = ''
    #   Identifier     "Device0"
    #   Driver         "nvidia"
    #   VendorName     "NVIDIA Corporation"
    #   BoardName      "NVIDIA GeForce RTX 2060"
    #   Option         "Coolbits" "4"
    # '';
    # monitorSection = ''
    #   # HorizSync source: edid, VertRefresh source: edid
    #   Identifier     "Monitor0"
    #   VendorName     "Unknown"
    #   ModelName      "Idek Iiyama PL3461WQ"
    #   HorizSync       217.0 - 217.0
    #   VertRefresh     48.0 - 144.0
    #   Option         "DPMS"
    # '';
    exportConfiguration = true;
  };
  hardware.nvidia.powerManagement.enable = true;

  environment.etc."X11/Xwrapper.config".text = ''
    allowed_users=anybody
    needs_root_rights=yes
  '';
  services.nvfancontrol = {
    enable = true;
    configuration = ''
      0     0
      45    0
      50    30
      55    40
      60    50
      70    80
      75    100
    '';
    cliArgs = "-d -f -l 0";
  };

  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    nvtop
  ];

  # nixpkgs.config.packageOverrides = pkgs: {
  #   # vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  #   nvidia_x11 = pkgs.nvidia_x11;
  # };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
  };

  #   # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
  # hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
