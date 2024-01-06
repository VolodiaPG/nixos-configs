{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.mybtrfs;
in {
  options = {
    services.mybtrfs = {
      enable = mkEnableOption "mybtrfs";
    };
  };

  config = mkIf cfg.enable {
    boot.supportedFilesystems = ["btrfs"];
  };
}
