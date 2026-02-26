{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
with lib;
let
  inherit (flake) inputs;
  cfg = config.services.laputil;
in
{
  options = {
    services.laputil = with types; {
      enable = mkEnableOption "laputil";
    };
  };

  imports = [
    inputs.laputil.nixosModules.default
  ];

  config = mkIf cfg.enable {
    boot = {
      extraModulePackages = [
        pkgs.cpufreq-laputil
      ];

      kernelModules = [
        "cpufreq-laputil"
      ];
    };

    powerManagement.cpuFreqGovernor = mkForce "laputil";

    services = {
      tlp = {
        settings = {
          CPU_SCALING_GOVERNOR_ON_BATTERY = mkDefault "laputil";
          CPU_SCALING_GOVERNOR_ON_AC = mkDefault "laputil";
        };
      };
    };
  };
}
