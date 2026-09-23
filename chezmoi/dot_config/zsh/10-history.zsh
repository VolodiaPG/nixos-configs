# History — PLAN.MD task 2.6, from modules/home/zsh.nix.
#
# The generated ~/.zshrc set history options TWICE: once from Home Manager's
# own programs.zsh defaults (lines 39-60 of the generated file) and once from
# our initContent (lines 64-75), which ran later and therefore won. Only the
# net result is kept here. Where the two disagreed, ours is the survivor:
#
#   SAVEHIST          HM 10000        -> ours 2000000
#   NO_APPEND_HISTORY HM off          -> ours appendhistory (on)
#   NO_HIST_IGNORE_ALL_DUPS           -> ours hist_ignore_all_dups (on)
#
# HM-only options with no counterpart in initContent are preserved as-is.

export LC_ALL="C.UTF-8"

HISTSIZE=10000
SAVEHIST=2000000
HISTFILE="$HOME/.zsh_history"

setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_fcntl_lock
unsetopt extended_history
unsetopt hist_expire_dups_first
unsetopt hist_find_no_dups
unsetopt hist_save_no_dups

HISTORY_IGNORE="(ls|ll|ls -alh|pwd|clear|c|history|htop)"
