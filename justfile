_default: homemanager

homemanager:
    home-manager switch --flake .#volodia

updateindex:
    updateindex

switch: homemanager
    sudo nixos-rebuild switch --flake .#$(hostname)

boot: homemanager
    sudo nixos-rebuild boot --flake .#$(hostname)

test:
    sudo nixos-rebuild test --flake .#$(hostname)

update: updateindex
    nix flake update

bump: update switch
    git add flake.lock
    cog commit chore "Update" lock

fmt:
    nix fmt .
    
