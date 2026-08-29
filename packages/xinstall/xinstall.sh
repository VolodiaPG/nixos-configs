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
  nix eval --json "$REPO"#nixosConfigurations --apply 'cfg: builtins.attrNames cfg' 2>/dev/null |
    jq -r '.[] | select(. != "installer")' |
    gum choose --header "Select which configuration to install:"
)

if [ "$(nix eval --json "$REPO"#nixosConfigurations.\""$TARGET"\".config.services.impermanence.disko)" != "true" ]; then
  echo "disko installation is disabled because services.impermanence.disko is false for $TARGET." >&2
  exit 1
fi

if gum confirm --default=false "This will wipe data to install $TARGET:"; then
  echo building disko script for "$TARGET"...
  DISKO=$(nix build "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.destroyFormatMount --no-link --print-out-paths)
  echo executing disko script for "$TARGET"... in 10 seconds...
  sleep 10
  sudo "$(echo "$DISKO"/bin/*)" --yes-wipe-all-disks
elif gum confirm --default=false "Install $TARGET without wiping (mount existing system only)?"; then
  echo building disko mount script for "$TARGET"...
  MOUNT=$(nix build "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.mount --no-link --print-out-paths)
  echo mounting system for "$TARGET"...
  sudo "$(echo "$MOUNT"/bin/*)"
else
  exit 1
fi
echo building system for "$TARGET", and saving path to system.var.log...
SYSTEM=$(nix build --store /mnt "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.toplevel --no-link --print-out-paths)
echo "$SYSTEM" > system.var.log
echo installing system for "$TARGET"...
# No need to specify /mnt before SYSTEM
sudo nixos-install --root /mnt --no-channel-copy --no-root-passwd --system "$SYSTEM"
