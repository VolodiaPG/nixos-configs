# Completion and zsh plugins — PLAN.MD task 2.6, from modules/home/zsh.nix.
#
# Home Manager materialised three plugins into ~/.zsh/plugins/<name>/ as store
# symlinks and sourced them by absolute path. That directory dies with Home
# Manager, so each plugin is instead located at runtime across the places the
# three supported package managers put it:
#
#   nix       $NIX_PROFILES entries        (Determinate Nix is retained, §0)
#   dnf       /usr/share/...               (Nobara)
#   homebrew  /opt/homebrew/share/...      (macOS)
#
# A plugin that is installed nowhere is skipped silently rather than erroring,
# which is what makes this file safe to apply before the phase 3 package roles
# have run.

# fpath contributions must land before compinit.
() {
  local -a dirs
  local p
  for p in ${(z)NIX_PROFILES}; do
    dirs+=("$p/share/zsh/site-functions" "$p/share/zsh-completions/src")
  done
  dirs+=(
    /usr/share/zsh/site-functions
    /usr/share/zsh/vendor-completions
    /usr/share/zsh-completions/src
    /opt/homebrew/share/zsh/site-functions
    /opt/homebrew/share/zsh-completions
  )
  for p in $dirs; do
    [[ -d $p ]] && fpath=("$p" $fpath)
  done
}

# `just` completions came from an explicit `source ${pkgs.just}/share/zsh/
# site-functions/_just`. Every package manager above ships `_just` into one of
# the site-functions dirs already on fpath, so the hardcoded source is gone
# rather than reimplemented.
autoload -U compinit && compinit

# zsh-autosuggestions. Strategy list is ours (zsh.nix autosuggestion.strategy).
() {
  local p
  for p in \
    ${^${(z)NIX_PROFILES}}/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  do
    if [[ -f $p ]]; then
      source $p
      break
    fi
  done
}
ZSH_AUTOSUGGEST_STRATEGY=(history completion match_prev_cmd)

# nix-zsh-completions — only ever meaningful where Nix is installed, so it is
# looked up solely under $NIX_PROFILES.
() {
  local p
  for p in ${^${(z)NIX_PROFILES}}/share/nix-zsh-completions/nix-zsh-completions.zsh; do
    [[ -f $p ]] && source $p && break
  done
}

# NOT PORTED: the generated ~/.zshrc line 49 sourced
# catppuccin_mocha-zsh-syntax-highlighting.zsh from the store. zsh.nix sets
# `syntaxHighlighting.enable = false`, so zsh-syntax-highlighting itself was
# never loaded and that file only assigned ZSH_HIGHLIGHT_STYLES entries that
# nothing read. Vendoring an asset for a disabled feature would be dead
# weight; if syntax highlighting is ever turned on, re-add both together.
