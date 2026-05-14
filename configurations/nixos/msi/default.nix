{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./home.nix
    (self + "/secrets/nixos.nix")
    inputs.agenix.nixosModules.default
    self.nixosModules.all-modules
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-nvidia
    common-pc-ssd
  ]);

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    # nixCacheProxy.enable = true;
    wm = {
      enable = true;
      gnome.enable = true;
      niri = {
        enable = false;
      };
    };

    # Hardware and kernel
    kernel = {
      enable = true;
      latestKernel = true;
    };

    nvidia.enable = true;

    myScx = {
      enable = false;
      ac = {
        governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--performance";
        extraArgs = "";
      };
      battery = {
        governor = "schedutil";
        scheduler = "scx_lavd";
        args = "--powersave";
        extraArgs = "";
      };
    };

    myAnanicy.enable = true;
    virt.enable = true;
    elegantBoot.enable = true;
    hifi.enable = true;
    betterSleep.enable = true;
    # ccache.enable = true;
    caddy.enable = true;
    homeLab.enable = false;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "disk/by-label/root";
    };
    networking.enable = false;
    vpn.enable = true;

    # From nixos
    # blueman.enable = true;
    blocky.enable = false;

    immich-ml = {
      enable = true;
    };
    my_virtualization.enable = true;
  };

  # Hardware
  hardware.cpu.intel.updateMicrocode = true;
  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true;
  #   extraPackages = with pkgs; [
  #     libvdpau-va-gl
  #     nvidia-vaapi-driver
  #     libva-vdpau-driver
  #   ];
  # };

  # environment.etc."X11/xorg.conf.d/10-nvidia.conf".text = ''
  #   Section "OutputClass"
  #     Identifier "nvidia"
  #     MatchDriver "nvidia-drm"
  #     Driver "nvidia"
  #     Option "PrimaryGPU" "yes"
  #   EndSection
  # '';

  system.stateVersion = "22.05";
}
