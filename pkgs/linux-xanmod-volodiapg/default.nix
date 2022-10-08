{ pkgs
, stdenv
, lib
, fetchFromGitHub
, buildLinux
, ...
} @ args:

# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/linux-xanmod.nix
let
  major = "6.0";
  minor = "0";
  version = "${major}.${minor}";
  release = "1";

  # patches-src = fetchFromGitHub {
  #   owner = "xanmod";
  #   repo = "linux-patches";
  #   rev = "8f964c6";
  #   sha256 = "sha256-/kMBPEqsxYMJsPTgcv9xP81nt7R8a9ioveuQko6l5X8=";
  # };
in
buildLinux {
  inherit stdenv lib version;

  src = fetchFromGitHub {
    owner = "xanmod";
    repo = "linux";
    rev = "${version}-xanmod${release}";
    sha256 = "sha256-E7T8eHwMKYShv4KWdCbHQmpn+54edJoKdimZY3GFbPU=";
  };

  modDirVersion = "${version}-volodiapg-xanmod${release}";

  structuredExtraConfig = import ./config.nix args;

  kernelPatches = [ ];

  # kernelPatches = (builtins.map
  #   (name: {
  #     inherit name;
  #     patch = name;
  #   })
  #   (lib.filesystem.listFilesRecursive "${patches-src}/linux-${major}.y-xanmod/xanmod"));
  #   # [
  #   #   # Block patches. Set BFQ as default
  #   #   # "${patches-src}/${major}/block/0001-block-Kconfig.iosched-set-default-value-of-IOSCHED_B.patch"
  #   #   # "${patches-src}/${major}/block/0002-block-Fix-depends-for-BLK_DEV_ZONED.patch"
  #   #   # "${patches-src}/${major}/block/0002-LL-elevator-set-default-scheduler-to-bfq-for-blk-mq.patch"
  #   #   # "${patches-src}/${major}/block/0003-LL-elevator-always-use-bfq-unless-overridden-by-flag.patch"

  #   #   # "${patches-src}/${major}/intel/xanmod/0001-intel_rapl-Silence-rapl-trace-debug.patch"
  #   #   # "${patches-src}/${major}/intel/xanmod/0002-firmware-Enable-stateless-firmware-loading.patch "
  #   #   # "${patches-src}/${major}/intel/xanmod/0003-locking-rwsem-spin-faster.patch"
  #   #   # "${patches-src}/${major}/intel/xanmod/0004-drivers-initialize-ata-before-graphics.patch"
  #   #   # "${patches-src}/${major}/intel/xanmod/0005-init-wait-for-partition-and-retry-scan.patch"

  #   #   # "${patches-src}/${major}/clearlinux/sirlucjan/0001-clearlinux-5.18-introduce-clearlinux-patchset-v8.patch"
  #   # ]);



  extraMeta.broken = !stdenv.hostPlatform.isx86_64;
}
