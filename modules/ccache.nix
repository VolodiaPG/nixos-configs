_: {
  config.nixos.ccache =
    {
      lib,
      config,
      ...
    }:
    with lib;
    {
      nix.settings.extra-sandbox-paths = [ (toString config.programs.ccache.cacheDir) ];
      programs.ccache = {
        enable = true;
        cacheDir = "/nix/var/cache/ccache";
        packageNames = [ ];
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
            callPackage =
              path: args:
              (prev.callPackage path (
                args
                // {
                  stdenv = final.ccacheStdenv;
                  autoModules = true;
                  buildLinux = attrs: final.buildLinux (attrs // { });
                }
              ));
          };
        })
      ];
    };
}
