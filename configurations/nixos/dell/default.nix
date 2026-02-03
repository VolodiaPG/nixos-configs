{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.nixosModules.default
    ./configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    gfxmodeEfi = "2560x1440";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dell";
  networking.hostId = "30249675";

  services = {
    kernel.enable = true;
    intel.enable = true;
    nvidia.enable = true;
    virt.enable = true;
    impermanence.enable = true;
    vpn.enable = true;
    laptopServer.enable = true;
    home-lab.enable = true;
    nix-cache-proxy.enable = true;
    caddy.enable = true;
  };

  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
      vaapiVdpau
      libvdpau-va-gl
      nvidia-vaapi-driver
      (vaapiIntel.override { enableHybridCodec = true; })
    ];
  };

  environment.etc."X11/xorg.conf.d/10-nvidia.conf".text = ''
    Section "OutputClass"
      Identifier "nvidia"
      MatchDriver "nvidia-drm"
      Driver "nvidia"
      Option "PrimaryGPU" "yes"
    EndSection
  '';

  system.stateVersion = "22.05";
}
