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
      # Would work for any kernel, but not for linux-ashi since it's package differently
      packageNames = [
        #   "linux-asahi"
        # "scx.rustscheds"
      ];
    };

    nixpkgs.overlays = [
      (final: prev: {
        ccacheWrapper = prev.ccacheWrapper.override {
          extraConfig = ''
            export CCACHE_COMPRESS=1
            export CCACHE_DIR="${config.programs.ccache.cacheDir}"
            export CCACHE_UMASK=007
            export CCACHE_SLOPPINESS=random_seed
            if [ ! -d "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' does not exist"
              echo "Please create it with:"
              echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
              echo "  sudo chown root:nixbld '$CCACHE_DIR'"
              echo "====="
              exit 1
            fi
            if [ ! -w "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
              echo "Please verify its access permissions"
              echo "====="
              exit 1
            fi
          '';
        };
        linux-asahi = prev.linux-asahi.override {
          # callPackage = safeCall prev;
          # Intercept callPackage
          callPackage =
            path: args:
            (prev.callPackage path (
              args
              // {
                # Inject your custom stdenv here
                stdenv = final.ccacheStdenv;

                autoModules = true;

                # If you want to modify buildLinux itself:
                buildLinux =
                  attrs:
                  final.buildLinux (
                    attrs
                    // {
                      # Add custom build flags or post-patches here
                      # example: nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [ pkgs.myTool ];
                    }
                  );
              }
            ));
        };
      })
    ];
  };
}
