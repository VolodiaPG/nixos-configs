_: {
  config.nixos.auto-upgrade =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
      cfg = config.services.autoUpgrade;
      isClean = cfg.inputs.self ? rev;
    in
    {
      options.services.autoUpgrade = {
        flakeURL = mkOption {
          description = "Flake url to pull from";
          type = types.str;
        };
        inputs = mkOption {
          description = "Flake inputs";
          type = types.attrs;
        };
      };

      config = {
        system.autoUpgrade = {
          allowReboot = true;
          enable = isClean;
          flags = [ "--refresh" ];
          flake = cfg.flakeURL;
        };

        systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
          serviceConfig.ExecCondition = lib.getExe (
            pkgs.writeShellScriptBin "check-date" ''
              lastModified() {
                nix flake metadata "$1" --refresh --json | ${lib.getExe pkgs.jq} '.lastModified'
              }
              test "$(lastModified "${config.system.autoUpgrade.flake}")" -gt "$(lastModified "self")"
            ''
          );
        };
      };
    };
}
