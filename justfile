_default: boot

build drv="$(hostname)":
    nom-build . -A nixosConfigurations.{{drv}}.config.system.build.toplevel

boot drv="$(hostname)": (build drv)
    sudo nix-env --profile /nix/var/nix/profiles/system --set ./result
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

switch drv="$(hostname)": (build drv)
    nvd diff /run/current-system ./result
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

deploy node="home-server" *flags:
    deploy -f . {{node}} --skip-checks {{flags}}

secret-edit:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/secrets
    chosen=$(ls *.age | gum choose --header "Select which secret to edit:")
    ragenix -e "$chosen"

update:
    #!/usr/bin/env bash
    set -euo pipefail
    npins update
    just switch
    just deploy
