{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.ccache;
in
{
  options.services.ccache = {
    enable = lib.mkEnableOption "ccache, especially for linux kernel";
  };
  config = mkIf cfg.enable {
    nix.settings.extra-sandbox-paths = [ (toString config.programs.ccache.cacheDir) ];
    programs.ccache = {
      enable = true;
      cacheDir = "/nix/var/cache/ccache";
      packageNames = [
        "linux_ccache"
      ];
    };
  };
}
