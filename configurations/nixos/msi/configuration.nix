{
  flake,
  ...
}:
let
  inherit (flake) inputs;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
  ];

  # Host-specific configuration
  boot = {
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

  # services = {
  #   undervolt = {
  #     enable = true;
  #     coreOffset = -95;
  #     gpuOffset = -95;
  #     uncoreOffset = -95;
  #     analogioOffset = -95;
  #   };
  # };

  hardware = {
    cpu.intel.updateMicrocode = true;
  };

  # environment = {
  #   # etc = {
  #   #   "X11/Xwrapper.config".text = ''
  #   #     allowed_users=anybody
  #   #     needs_root_rights=yes
  #   #   '';
  #   #   "X11/xorg.conf".text = lib.mkForce (builtins.readFile ./xorg.conf);
  #   # };
  #   sessionVariables = {
  #     LIBVA_DRIVER_NAME = "nvidia";
  #   };
  # };

  system.stateVersion = "22.05";
}
