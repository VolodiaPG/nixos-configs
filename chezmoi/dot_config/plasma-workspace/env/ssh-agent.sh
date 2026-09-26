# shellcheck shell=sh
# Plasma sources this at session start. Same file name as
# /etc/xdg/plasma-workspace/env/ssh-agent.sh (kde-settings-plasma), which it
# therefore replaces. That script points SSH_AUTH_SOCK at
# $XDG_RUNTIME_DIR/ssh-agent.socket (OpenSSH's agent). This one points it at
# the Bitwarden Flatpak's agent, so apps started from Plasma, not only
# shells, use Bitwarden. Unlike the system script, it sets the value even
# when one is already present, because the system agent's value is exactly
# what it replaces.
SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
export SSH_AUTH_SOCK
