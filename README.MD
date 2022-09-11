https://github.com/Maxwell-lt/machine-configuration/tree/master/pkgs
https://github.com/xddxdd/nixos-config/tree/master/nixos/client-components
https://github.com/mrkkrp/nixos-config/tree/master/imports/symlinks


nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"