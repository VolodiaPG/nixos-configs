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
    gum choose --header "Select which configuration to mount:"
)

if [ "$(nix eval --json "$REPO"#nixosConfigurations.\""$TARGET"\".config.services.impermanence.disko)" != "true" ]; then
  echo "disko mount is disabled because services.impermanence.disko is false for $TARGET." >&2
  exit 1
fi

gum confirm --default=false "This will mount the $TARGET system to /mnt:"

echo building disko mount script for "$TARGET"...
MOUNT=$(nix build "$REPO"#nixosConfigurations.\""$TARGET"\".config.system.build.mount --no-link --print-out-paths)

exec sudo "$(echo "$MOUNT"/bin/*)"
