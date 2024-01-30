_default: homemanager-basic

homemanager:
    home-manager switch --flake .#volodia

homemanager-basic:
    nix develop .# -c home-manager switch --flake .#volodia.no-de.no-apps.no-machine

updateindex:
    updateindex

boot: 
    sudo nixos-rebuild boot --flake .#$(hostname)

_switch:
    sudo nixos-rebuild switch --flake .#$(hostname)
    
switch:
    #!/usr/bin/env bash
    (setsid nohup sudo bash -c "sleep 60 ; sudo nix-env --rollback --profile /nix/var/nix/profiles/system ; echo \"Rollbacked $(date)\"")& disown
    nohup_command_pid=$!
    
    just _switch

    echo "--> 60 seconds before rollback..."

    select result in Keep Rollback
    do
        if [ $result == "Keep" ]; then
            kill $nohup_command_pid
            break
        elif [ $result == "Rollback" ]; then
            wait
            break
        fi
    done

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
    
