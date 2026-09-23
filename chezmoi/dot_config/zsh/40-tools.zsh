# Tool shell integrations — PLAN.MD task 2.6.
#
# Home Manager wrote each of these as an absolute /nix/store path. Every one
# is now resolved through $PATH with a `command -v` guard, so a host that has
# not finished its phase 3 package role degrades to a plain shell instead of
# erroring on every prompt.
#
# Relative order is preserved from the generated ~/.zshrc, except zoxide,
# which moved to 90-zoxide.zsh — see the note there.

# fzf keybindings and completion. `$options[zle]` guard is HM's: skip in
# non-ZLE shells, where binding keys is meaningless.
if [[ $options[zle] = on ]] && (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# nix-index's command-not-found handler. Nix-only by construction; skipped
# entirely where Nix is absent. nix-index-database ships the profile.d
# snippet, so look for it under the profiles rather than on PATH.
() {
  local p
  for p in ${^${(z)NIX_PROFILES}}/etc/profile.d/command-not-found.sh; do
    [[ -f $p ]] && source $p && break
  done
}

# keychain: reuse one ssh-agent across shells and hold id_ed25519 unlocked.
# On Linux this is what exports SSH_AUTH_SOCK; on macOS ~/.zshenv has already
# pointed it at the per-user temp dir and keychain adopts that socket.
if (( $+commands[keychain] )); then
  eval "$(SHELL=zsh keychain --eval --quiet id_ed25519)"
fi

if [[ -o interactive ]]; then
  # theme-switcher is packages/theme-switcher, reinstalled to ~/.local/bin by
  # PLAN.MD task 4.1. Backgrounded and disowned (&|) exactly as before so it
  # never delays the first prompt.
  if (( $+commands[theme-switcher] )); then
    theme-switcher -t tmux,kitty &> /dev/null &|
  fi

  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi

# direnv. `silent = true` in interactive.nix became DIRENV_LOG_FORMAT="" in
# ~/.config/direnv/direnvrc, which task 2.5 already ported, so the hook here
# is the plain one.
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# NOT PORTED: the NixOS version banner ("Running Nixos <ver> (version last
# updated N days ago)" / "Running Nix"). It shelled out to `nixos-version`
# and to the date_since_last_nixpkgs script built by zsh.nix. Neither Nobara
# nor macOS has nixos-version, so the branch could only ever print the
# constant string "Running Nix" on both remaining hosts. Dropped as dead
# output rather than reimplemented.
