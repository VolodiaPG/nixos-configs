{ pkgs
, stdenv
, lib
, fetchFromGitHub
, buildLinux
, ...
} @ args:

# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/linux-xanmod.nix
let
  major = "5.19";
  minor = "10";
  version = "${major}.${minor}";
  release = "1";

  patches-src = fetchFromGitHub {
    owner = "blacksky3";
    repo = "patches";
    rev = "ec53ede6ca654e006a3ff185cb55820d143b0876";
    sha256 = "sha256-CtlwjS9otdlTBRuN+x1DaVe0ij2SMAI42j6ORExzN7I=";
  };
in
buildLinux {
  inherit stdenv lib version;

  src = fetchFromGitHub {
    owner = "xanmod";
    repo = "linux";
    rev = "${version}-xanmod${release}";
    sha256 = "sha256-iuflUPw+CqJKBOfrjNxYoBUXo3RygV4zPgq3pVxhT0s=";
  };

  modDirVersion = "${version}-xanmod${release}-volodiapg";

  structuredExtraConfig = import ./config.nix args;

  kernelPatches = [
    pkgs.kernelPatches.bridge_stp_helper
    pkgs.kernelPatches.request_key_helper
  ] ++
  (builtins.map
    (name: {
      inherit name;
      patch = name;
    })
    # (lib.filesystem.listFilesRecursive "${patches-src}/${major}"));
    [
      # Block patches. Set BFQ as default
      # "${patches-src}/${major}/block/0001-block-Kconfig.iosched-set-default-value-of-IOSCHED_B.patch"
      # "${patches-src}/${major}/block/0002-block-Fix-depends-for-BLK_DEV_ZONED.patch"
      # "${patches-src}/${major}/block/0002-LL-elevator-set-default-scheduler-to-bfq-for-blk-mq.patch"
      # "${patches-src}/${major}/block/0003-LL-elevator-always-use-bfq-unless-overridden-by-flag.patch"
      
      # "${patches-src}/${major}/intel/xanmod/0001-intel_rapl-Silence-rapl-trace-debug.patch"
      # "${patches-src}/${major}/intel/xanmod/0002-firmware-Enable-stateless-firmware-loading.patch "
      # "${patches-src}/${major}/intel/xanmod/0003-locking-rwsem-spin-faster.patch"
      # "${patches-src}/${major}/intel/xanmod/0004-drivers-initialize-ata-before-graphics.patch"
      # "${patches-src}/${major}/intel/xanmod/0005-init-wait-for-partition-and-retry-scan.patch"

      # "${patches-src}/${major}/clearlinux/sirlucjan/0001-clearlinux-5.18-introduce-clearlinux-patchset-v8.patch"
    ]);



  extraMeta.broken = !stdenv.hostPlatform.isx86_64;
}
