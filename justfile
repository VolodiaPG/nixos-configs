# Recipes for building, deploying and debugging this flake.
# `just --list` shows them with these comments.

_default: boot

# --- Build / activate -------------------------------------------------------

# Build a host without activating it
build drv="$(hostname)":
    nh os build . -H {{ drv }}

# Build and activate on next boot
boot drv="$(hostname)":
    nh os boot . -H {{ drv }}

# Build and activate now
switch drv="$(hostname)":
    nh os switch . -H {{ drv }}

# Build and show what would change against the running system
dry-build drv="$(hostname)": (build drv)
    nvd diff /run/current-system ./result

# What nix would have to build/fetch, without building it
dry drv="$(hostname)":
    nom build .#nixosConfigurations.{{ drv }}.config.system.build.toplevel --dry-run

# Build the darwin system and diff it against the running one
mac-build:
    nom build .#darwinConfigurations.Volodias-MacBook-Pro.system
    nvd diff /run/current-system ./result

# Activate the darwin system
mac-switch:
    nh darwin switch . -H Volodias-MacBook-Pro

# Deploy a remote host over SSH (deploy-rs)
deploy node="home-server" *flags:
    deploy .#{{ node }} --skip-checks {{ flags }}

# --- Installer --------------------------------------------------------------

# Build the installer ISO into ./result
installer:
    nom build .#nixosConfigurations.installer.config.system.build.isoImage

# Write the ISO built by `just installer` to a device
installer-burn devpath:
    #!/usr/bin/env bash
    set -euo pipefail
    dd if=$(ls {{ justfile_directory() }}/result/iso/nixos*) of={{ devpath }} bs=8M status=progress

# --- Check / debug ----------------------------------------------------------

# Lint hooks + evaluate every configuration
check:
    nix flake check

# Format every nix file
fmt:
    nix fmt

# Run the pre-commit hooks over the whole tree
lint:
    prek run --all-files

# Evaluate one host to a .drv — the fastest "did I break it?"
eval drv="$(hostname)":
    nix eval --raw .#nixosConfigurations.{{ drv }}.config.system.build.toplevel.drvPath

# Evaluate every host, including the darwin one (cross-platform eval is fine)
eval-all:
    #!/usr/bin/env bash
    set -uo pipefail
    status=0
    for host in $(nix eval --raw --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)' .#nixosConfigurations); do
        printf '%-14s ' "$host"
        nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" || status=1
        echo
    done
    for host in $(nix eval --raw --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)' .#darwinConfigurations); do
        printf '%-14s ' "$host"
        nix eval --raw ".#darwinConfigurations.$host.config.system.build.toplevel.drvPath" || status=1
        echo
    done
    exit $status

# Evaluate a host with a full stack trace
trace drv="$(hostname)":
    nix eval --show-trace --raw .#nixosConfigurations.{{ drv }}.config.system.build.toplevel.drvPath

# Print one evaluated option, e.g. `just option msi my.impermanence.fsType`
option drv path:
    nix eval --json .#nixosConfigurations.{{ drv }}.config.{{ path }}

# Open a repl with a host's config/options/pkgs in scope
repl drv="$(hostname)":
    nix repl .#nixosConfigurations.{{ drv }}

# Build everything a host installs, so the cache is warm (used by CI).
# Builds only the packages (not the full system closure, which drags in
# boot/initrd/activation-script derivations that cachix-push filters out
# anyway) as installables in a single `nix build` call, so substitution
# happens as one batched query instead of one nix-eval-jobs job per package.
# Outputs the resulting store paths to ./out-paths-[host].txt
ci host="$(hostname)":
    #!/usr/bin/env bash
    set -euxo pipefail
    toDrvArgs='pkgs: builtins.concatStringsSep " " (map (p: p.drvPath) pkgs)'
    system_drvs=$(nix eval --raw ".#nixosConfigurations.{{host}}.config.environment.systemPackages" --apply "$toDrvArgs")
    home_drvs=$(nix eval --raw ".#nixosConfigurations.{{host}}.config.home-manager.users.volodia.home.packages" --apply "$toDrvArgs")
    nix build --no-link --print-out-paths $system_drvs $home_drvs > ./out-paths-{{host}}.txt

# --- Secrets ----------------------------------------------------------------

# Pick an agenix secret from a menu and edit it
secret-edit:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/secrets
    chosen=$(ls *.age | gum choose --header "Select which secret to edit:")
    ragenix -e "$chosen"

# Create a new agenix secret (declare it in secrets/secrets.nix first)
secret-new filename:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/secrets
    ragenix -e "{{ filename }}"

# --- Maintenance ------------------------------------------------------------

# Update every input, then rebuild this host and redeploy home-server
update:
    #!/usr/bin/env bash
    set -euo pipefail
    nix flake update
    just boot
    flatpak update
    just deploy
