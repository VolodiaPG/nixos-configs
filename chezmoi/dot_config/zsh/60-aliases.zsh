# Aliases — PLAN.MD task 2.6, from modules/home/zsh.nix shellAliases.

alias c='clear'
alias g='git'
alias ga='git add .'
alias gm='git commit -m'
alias j='just'
alias jl='just --list'
alias journalctl-10min="journalctl --user -xe -b --since '10 min ago'"
alias ll='ls -l'
alias n='vim'

# NOT PORTED: `oc` and `opencode-agents`. opencode is dropped in PLAN.MD §0;
# chezmoi/dot_config/opencode/ was deleted in commit bec7e34, so both aliases
# would point at a program that is no longer installed and a config file that
# no longer exists.
