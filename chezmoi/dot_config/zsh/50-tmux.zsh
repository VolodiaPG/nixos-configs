# tmux session auto-naming — PLAN.MD task 2.6, from modules/home/zsh.nix.
#
# Renames the tmux session after the git repo (plus branch) or directory you
# cd into. Unchanged from the generated ~/.zshrc: it was already plain shell
# with no store paths.
#
# Pairs with chezmoi/dot_config/tmux/tmux.conf, whose status line colours the
# session name via ~/.local/bin/tmux-session-color (task 4.1).

if [ -n "$TMUX" ]; then
  function refresh_tmux_session_name() {
    local pane_index=$(tmux display-message -p '#P')
    [ "$pane_index" != "1" ] && return

    local current_session=$(tmux display-message -p '#S')
    local current_dir=$(basename "$PWD")

    if [ ! "$current_session" = "$current_dir" ]; then
      if git rev-parse --git-dir > /dev/null 2>&1; then
        tmux rename-session "$(basename $(git rev-parse --show-toplevel)) ($(git branch --show-current))"
      else
        tmux rename-session "$current_dir"
      fi
    fi
  }
  chpwd() {
    refresh_tmux_session_name
  }
  refresh_tmux_session_name
fi
