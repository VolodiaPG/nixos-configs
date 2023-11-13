_default: homemanager

homemanager:
    home-manager switch --flake .#volodia

homemanager-basic:
    home-manager switch --flake .#volodia.no-de.personal

updateindex:
    updateindex

boot: 
    sudo nixos-rebuild boot --flake .#$(hostname)
    just homemanager

switch: boot
    sudo nixos-rebuild switch --flake .#$(hostname)

test:
    sudo nixos-rebuild test --flake .#$(hostname)

update: updateindex
    nix flake update

bump: update switch
    git add flake.lock
    cog commit chore "Update" lock

darwin:
    darwin-rebuild switch --flake .

fmt:
    nix fmt .
    
