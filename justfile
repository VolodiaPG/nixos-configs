default: boot
    
switch:
    sudo nixos-rebuild switch --flake .#$(hostname)

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)
    
fmt:
    nix fmt .
    
