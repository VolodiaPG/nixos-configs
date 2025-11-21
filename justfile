_default: homemanager-basic

homemanager:
    home-manager switch --flake .#volodia

homemanager-basic:
    nix develop .# -c home-manager switch --flake .#volodia.no-de.personal.no-machine

updateindex:
    updateindex

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

_switch:
    sudo nixos-rebuild switch --flake .#$(hostname)

mount hostname:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount {{justfile_directory()}}/machines/{{hostname}}/disk.nix

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

toto:
  echo {{ justfile_directory() }}

darwin:
  #!/usr/bin/env bash
  set -e
  # result=$(nix build --impure --print-out-paths --expr "
  #   let
  #   self = builtins.getFlake ''path://{{ justfile_directory() }}'';
  #   configuration =
  # self.darwinConfigurationsFunctions.aarch64-darwin.Volodias-MacBook-Pro
  # {symlinkPath = ''{{ justfile_directory() }}/users/volodia'';};
  #   in
  #   configuration")
  # echo $result
  # sudo $result/activate
  result=$(nix build .#darwinConfigurations.Volodias-MacBook-Pro.system --print-out-paths)
  echo $result
  sudo $result/activate



fmt:
    nix fmt .

sops_setup:
  mkdir -p ~/.config/sops/age
  ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
