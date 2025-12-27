_default: boot

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

switch:
    sudo nixos-rebuild switch --flake .#$(hostname) --accept-flake-config

mount hostname:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount {{justfile_directory()}}/machines/{{hostname}}/disk.nix

test:
    sudo nixos-rebuild test --flake .#$(hostname)

darwin:
  #!/usr/bin/env bash
  set -e
  result=$(nix build .#darwinConfigurations.Volodias-MacBook-Pro.system --print-out-paths --accept-flake-config)
  sudo $result/activate || echo Failed $result
