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
    echo "disko-install is disabled because services.impermanence.disko is false for $TARGET." >&2
    exit 1
fi

BLOCKDEV=$(
    lsblk --json 2>/dev/null |
        jq -r '.["blockdevices"].[] | "\(.name) (\(.size))"' |
        gum choose --header "Select disk to erase and install nixos on:" |
        awk -F ' ' '{print $1}'
)
DISK="/dev/$BLOCKDEV"

gum confirm --default=false "This will erase $DISK to install $TARGET, confirm:"

echo selected "$FLAKE"#"$TARGET"
# exec disko-install --flake "$FLAKE"#"$TARGET" --disk main "$DISK"
sudo disko --mode disko --flake "$FLAKE"#"$TARGET" --disk main "$DISK"
sudo nixos-install --no-channel-copy --no-root-passwd --flake "$FLAKE"#"$TARGET"
