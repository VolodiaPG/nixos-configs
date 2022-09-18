https://github.com/Maxwell-lt/machine-configuration/tree/master/pkgs
https://github.com/xddxdd/nixos-config/tree/master/nixos/client-components
https://github.com/mrkkrp/nixos-config/tree/master/imports/symlinks

https://github.com/LunNova/nixos-configs/blob/dev/flake.nix
https://github.com/kclejeune/system/blob/master/modules/home-manager/default.nix

Migration inspired from: https://gist.github.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620

https://www.lucacambiaghi.com/nixpkgs/readme.html#orga1939e8

nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"

Resources:
Lan Tian: https://lantian.pub/en/article/modify-website/nixos-why.lantian/
Awesome Nix: https://nix-community.github.io/awesome-nix/#community
Hardware specifics: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel.nix
ZFS (encrypted) install: https://timklampe.cool/docs/example/nixos/nixos_install/

inspiration:
https://github.com/sandydoo/vapoursynth-on-nix