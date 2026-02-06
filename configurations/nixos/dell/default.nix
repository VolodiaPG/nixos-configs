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
    common-cpu-intel-cpu-only
    common-gpu-intel
    common-pc
    common-pc-laptop
    common-pc-laptop-ssd
  ]);

  # Enable services via module options
  services = {
    # Core system services
    base.enable = true;
    commonNixSettings.enable = true;
    nixCacheProxy.enable = true;

    # Hardware and kernel
    kernel.enable = true;
    intel.enable = true;
    nvidia.enable = true;
    virt.enable = true;

    # Storage and networking
    impermanence = {
      enable = true;
      rootVolume = "nvme0n1p11";
    };
    vpn.enable = true;
    laptopServer.enable = true;
    backlightOff.enable = true;
    homeLab.enable = true;
    caddy.enable = true;
  };
}
