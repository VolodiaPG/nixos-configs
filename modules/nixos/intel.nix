{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.services.intel;
in
{
  options = {
    services.intel = {
      enable = mkEnableOption "intel";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      extraModprobeConfig = ''
        options kvm_intel nested=1
        options i915 enable_guc=3 enable_fbc=1 fastboot=1
      '';
      kernelModules = [ "kvm_intel" ];
      kernelParams = [
        "intel_iommu=on"
        "intel_pstate=active"
      ];
    };

    environment.systemPackages = [ pkgs.intel-gpu-tools ];
  };
}
