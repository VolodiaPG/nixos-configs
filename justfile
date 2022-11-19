default: boot
    
switch:
    sudo nixos-rebuild switch --flake .#$(hostname)

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

test:
    sudo nixos-rebuild test --flake .#$(hostname)
    
fmt:
    nix fmt .
    
