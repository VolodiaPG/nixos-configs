default: boot

updateindex:
    updateindex

switch:
    sudo nixos-rebuild switch --flake .#$(hostname)

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

test:
    sudo nixos-rebuild test --flake .#$(hostname)

update: updateindex
    nix flake update

fmt:
    nix fmt .
    
