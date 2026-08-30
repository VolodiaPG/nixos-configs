_default: boot

build drv="$(hostname)":
    nom build .#nixosConfigurations.{{ drv }}.config.system.build.toplevel

boot drv="$(hostname)": (build drv)
    sudo nix-env --profile /nix/var/nix/profiles/system --set ./result
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

switch drv="$(hostname)":
    nh os switch . -H {{ drv }}

installer:
    nom build .#nixosConfigurations.installer.config.system.build.isoImage

dry drv="$(hostname)":
    nom build .#nixosConfigurations.{{ drv }}.config.system.build.toplevel --dry-run

dry-build drv="$(hostname)": (build drv)
    nvd diff /run/current-system ./result

mac-build:
    nom build .#darwinConfigurations.Volodias-MacBook-Pro.system
    nvd diff /run/current-system ./result

mac-switch:
    nh darwin switch . -H Volodias-MacBook-Pro

deploy node="home-server" *flags:
    deploy -f . {{ node }} --skip-checks {{ flags }}

secret-edit:
    #!/usr/bin/env bash
    cd {{ justfile_directory() }}/secrets
    chosen=$(ls *.age | gum choose --header "Select which secret to edit:")
    ragenix -e "$chosen"

secret-new filename:
    #!/usr/bin/env bash
    cd {{ justfile_directory() }}/secrets
    ragenix -e "{{ filename }}"

# Install encrypted secrets to /persistent
install-encrypted:
    #!/usr/bin/env bash
    cd {{ justfile_directory() }}/encrypted
    transcrypt -d

update:
    #!/usr/bin/env bash
    set -euo pipefail
    nix flake update
    just boot
    just deploy
