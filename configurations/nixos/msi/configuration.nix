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

  services = {
    undervolt = {
      enable = true;
      coreOffset = -55;
      gpuOffset = -55;
      uncoreOffset = -55;
      analogioOffset = -55;
    };
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

  # Nvidia gpu are slow to move up frequency, and cause stutter when scrolling, regularly
  systemd.services.nvidia-frequency = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      /run/current-system/sw/bin/nvidia-smi -lmc 1620,2100
      /run/current-system/sw/bin/nvidia-smi -lgc 210,3105
    '';
  };

  system.stateVersion = "22.05";
}
