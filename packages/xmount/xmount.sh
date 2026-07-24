#!/usr/bin/env bash
set -euo pipefail

FLAKE="github:volodiapg/nixos-configs"

echo Getting "$FLAKE"...

TARGET=$(
    nix flake show "$FLAKE" --json 2>/dev/null |
        jq -r '.["inventory"]["nixosConfigurations"]["output"]["children"] | keys[] | select(. != "installer")' |
        gum choose --header "Select which configuration to install:"
)

if [ "$(nix eval "$FLAKE#nixosConfigurations.$TARGET.config.services.impermanence.disko" --json)" != "true" ]; then
    echo "disko installation and further installation is disabled because services.impermanence.disko is false for $TARGET." >&2
    exit 1
fi

gum confirm --default=false "This will mount the $TARGET system to /mnt:"

exec sudo disko --mode mount --flake "$FLAKE"#"$TARGET"
