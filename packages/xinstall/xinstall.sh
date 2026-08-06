#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/volodiapg/nixos-configs"
# ponytail: XOS_REPO points at a local checkout to skip the clone (testing / reinstall from an existing repo)
REPO="${XOS_REPO:-}"

if [ -z "$REPO" ]; then
  REPO=$(mktemp -d)
  trap 'rm -rf "$REPO"' EXIT
  echo Cloning "$REPO_URL"...
  git clone --depth=1 "$REPO_URL" "$REPO"
fi

TARGET=$(
  nix eval --json --file "$REPO/default.nix" --apply 'cfg: builtins.attrNames cfg.nixosConfigurations' 2>/dev/null |
    jq -r '.[] | select(. != "installer")' |
    gum choose --header "Select which configuration to install:"
)

if [ "$(nix eval --json --file "$REPO/default.nix" --apply "cfg: cfg.nixosConfigurations.\"$TARGET\".config.services.impermanence.disko")" != "true" ]; then
  echo "disko installation is disabled because services.impermanence.disko is false for $TARGET." >&2
  exit 1
fi

gum confirm --default=false "This will wipe data to install $TARGET:"

echo building disko script for "$TARGET"...
DISKO=$(nix-build "$REPO" -A nixosConfigurations."$TARGET".config.system.build.destroyFormatMount --no-out-link)
echo executing disko script for "$TARGET"...
sudo "$(echo "$DISKO"/bin/*)" --yes-wipe-all-disks
echo building system for "$TARGET"...
SYSTEM=$(nix-build "$REPO" -A nixosConfigurations."$TARGET".config.system.build.toplevel --no-out-link)
echo installing system for "$TARGET"...
sudo nixos-install --no-channel-copy --no-root-passwd --system "$SYSTEM"
