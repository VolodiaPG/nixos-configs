_default: boot

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

switch drv=".#nixosConfigurations.$(hostname).config.system.build.toplevel":
    #!/usr/bin/env bash
    result=$(just dry {{drv}})
    sudo $result/activate || echo Failed $result

dry drv=".#nixosConfigurations.$(hostname).config.system.build.toplevel":
    #!/usr/bin/env bash
    result=$(nom build --print-out-paths --extra-experimental-features "nix-command flakes" {{drv}})
    nvd diff /run/current-system $result >&2
    echo $result

mount hostname:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount {{justfile_directory()}}/machines/{{hostname}}/disk.nix

test:
    sudo nixos-rebuild test --flake .#$(hostname)

dry-darwin drv=".#darwinConfigurations.Volodias-MacBook-Pro.system":
    just dry {{drv}}

darwin drv=".#darwinConfigurations.Volodias-MacBook-Pro.system":
  just dry {{drv}}
