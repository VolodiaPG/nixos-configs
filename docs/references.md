# References

Prior art and documentation collected while building this configuration.

## Other people's configurations

- <https://github.com/Maxwell-lt/machine-configuration/tree/master/pkgs>
- <https://github.com/xddxdd/nixos-config/tree/master/nixos/client-components>
- <https://github.com/mrkkrp/nixos-config/tree/master/imports/symlinks>
- <https://github.com/LunNova/nixos-configs/blob/dev/flake.nix>
- <https://github.com/kclejeune/system/blob/master/modules/home-manager/default.nix>
- <https://www.lucacambiaghi.com/nixpkgs/readme.html#orga1939e8>
- <https://github.com/sandydoo/vapoursynth-on-nix> (vapoursynth / mpv interpolation)

## Nix

- Awesome Nix: <https://nix-community.github.io/awesome-nix/#community>
- Lan Tian, "Why NixOS": <https://lantian.pub/en/article/modify-website/nixos-why.lantian/>
- Migration inspired by: <https://gist.github.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620>
- Build a package out of tree:
  `nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"`

## Hardware and filesystems

- nixos-hardware GPU modules:
  <https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel.nix>
- ZFS (encrypted) install:
  <https://timklampe.cool/docs/example/nixos/nixos_install/>,
  compression: <https://linuxhint.com/enable-zfs-compression/>
- btrfs install:
  <https://gist.github.com/hadilq/a491ca53076f38201a8aa48a0c6afef5>
  (encrypted variant:
  <https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58>)

## Misc

- Firefox font matching on Linux:
  <https://www.reddit.com/r/linux/comments/l1re17/psa_by_default_firefox_on_linux_doesnt_match_with/>
