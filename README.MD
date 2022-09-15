https://github.com/Maxwell-lt/machine-configuration/tree/master/pkgs
https://github.com/xddxdd/nixos-config/tree/master/nixos/client-components
https://github.com/mrkkrp/nixos-config/tree/master/imports/symlinks

Migration inspired from: https://gist.github.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620

nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"