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

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m"; # Time before waking to hibernate
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
