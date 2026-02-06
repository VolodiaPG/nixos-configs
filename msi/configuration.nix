{ }
#
# {
#   flake,
#   lib,
#   pkgs,
#   ...
# }:
# let
#   inherit (flake) inputs;
#   inherit (inputs) self;
#   inherit (flake.config) me;
# in
# {
#   imports = lib.flatten [
#     (with inputs.nixos-hardware.nixosModules; [
#       common-cpu-intel
#       common-gpu-nvidia
#       common-pc
#       common-pc-ssd
#     ])
#     ./hardware-configuration.nix
#   ];
#
#   # Host-specific configuration
#   boot = {
#     loader = {
#       efi.canTouchEfiVariables = true;
#       grub = {
#         enable = true;
#         device = "nodev";
#         efiSupport = true;
#         gfxmodeEfi = "3440x1440";
#       };
#     };
#     blacklistedKernelModules = [
#       "nouveau"
#       "iTCO_wdt"
#     ];
#   };
#
#   networking = {
#     hostId = "30249671";
#     hostName = "msi";
#     networkmanager.enable = true;
#   };
#
#   services = {
#     undervolt = {
#       enable = true;
#       coreOffset = -95;
#       gpuOffset = -95;
#       uncoreOffset = -95;
#       analogioOffset = -95;
#     };
#   };
#
#   hardware = {
#     cpu.intel.updateMicrocode = true;
#     graphics = {
#       enable = true;
#       extraPackages = with pkgs; [
#         libva-vdpau-driver
#         libvdpau-va-gl
#       ];
#     };
#     nvidia.prime.offload.enable = false;
#   };
#
#   environment = {
#     etc = {
#       "X11/Xwrapper.config".text = ''
#         allowed_users=anybody
#         needs_root_rights=yes
#       '';
#       "X11/xorg.conf".text = lib.mkForce (builtins.readFile ./xorg.conf);
#     };
#     sessionVariables = {
#       LIBVA_DRIVER_NAME = "nvidia";
#     };
#   };
#
#   system.stateVersion = "22.05";
# }
