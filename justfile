_default: boot

build drv="$(hostname)":
    nom-build . -A nixosConfigurations.{{drv}}.config.system.build.toplevel

boot drv="$(hostname)": (build drv)
    sudo nix-env --profile /nix/var/nix/profiles/system --set ./result
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

switch drv="$(hostname)": (build drv)
    sudo nix-env --profile /nix/var/nix/profiles/system --set ./result
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

installer:
    nom-build . -A nixosConfigurations.installer.config.system.build.isoImage

dry drv="$(hostname)":
    nom-build . -A nixosConfigurations.{{drv}}.config.system.build.toplevel --dry-run

mac-build:
    nom-build . -A darwinConfigurations.Volodias-MacBook-Pro.system

mac-switch: mac-build
    ./result/sw/bin/darwin-rebuild switch

update:
    npins update
