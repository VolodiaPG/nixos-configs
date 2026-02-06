{ }
#
# { flake, ... }:
# let
#   inherit (flake) inputs;
#   inherit (inputs) self;
# in
# {
#   imports = [
#     ./configuration.nix
#     inputs.nixos-hardware.nixosModules.common-cpu-intel
#     inputs.nixos-hardware.nixosModules.common-gpu-nvidia
#     inputs.nixos-hardware.nixosModules.common-pc-ssd
#     self.nixosModules.all-modules
#   ];
#
#   # Bootloader
#   boot.loader.grub = {
#     enable = true;
#     device = "nodev";
#     efiSupport = true;
#     gfxmodeEfi = "3440x1440";
#   };
#   boot.loader.efi.canTouchEfiVariables = true;
#
#   networking.hostName = "msi";
#   networking.hostId = "30249671";
#
#   # Enable services via module options
#   services = {
#     # Core system services
#     base.enable = true;
#     commonNixSettings.enable = true;
#     commonOverlays.enable = true;
#
#     # Hardware and kernel
#     kernel.enable = true;
#     intel.enable = true;
#     nvidia.enable = true;
#
#     # Desktop and applications
#     desktop.enable = true;
#     hifi.enable = true;
#     hyperhdr.enable = false;
#
#     # Storage and networking
#     impermanence.enable = true;
#     elegant-boot.enable = true;
#     vpn.enable = true;
#   };
#
#   # Hardware
#   hardware.cpu.intel.updateMicrocode = true;
#   hardware.graphics = {
#     enable = true;
#     enable32Bit = true;
#     extraPackages = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
#       vaapiVdpau
#       libvdpau-va-gl
#       nvidia-vaapi-driver
#     ];
#   };
#
#   environment.etc."X11/xorg.conf.d/10-nvidia.conf".text = ''
#     Section "OutputClass"
#       Identifier "nvidia"
#       MatchDriver "nvidia-drm"
#       Driver "nvidia"
#       Option "PrimaryGPU" "yes"
#     EndSection
#   '';
#
#   system.stateVersion = "22.05";
# }
