{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  # inherit (config.networking) hostName;
  # Only enable auto upgrade if current config came from a clean tree
  # This avoids accidental auto-upgrades when working locally.
  cfg = config.services.autoUpgrade;
in {
  options = {
    services.autoUpgrade = {
      enable = mkEnableOption "autoUpgrade";
      flakeURL = mkOption {
        description = "Flake url to pull from";
        type = types.str;
      };
      inputs = mkOption {
        description = "Flake inputs";
        type = types.attrs;
      };
    };
  };

  config = let
    isClean = cfg.inputs.self ? rev;
  in
    mkIf cfg.enable {
      system.autoUpgrade = {
        enable = isClean;
        dates = "hourly";
        flags = [
          "--refresh"
        ];
        flake = cfg.flakeURL;
        # flake = "git://m7.rs/nix-config?ref=release-${hostName}";
      };

      # Only run if current config (self) is older than the new one.
      systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
        serviceConfig.ExecCondition = lib.getExe (
          pkgs.writeShellScriptBin "check-date" ''
            lastModified() {
              nix flake metadata "$1" --refresh --json | ${lib.getExe pkgs.jq} '.lastModified'
            }
            test "$(lastModified "${config.system.autoUpgrade.flake}")"  -gt "$(lastModified "self")"
          ''
        );
      };
    };
}
