# zoxide — PLAN.MD task 2.6, from the catppuccin/HM-generated ~/.zshrc.
#
# `--cmd cd` shadows cd, so this must be the LAST thing to touch the cd
# builtin: zoxide's own doctor check warns (and was observed warning during
# this migration) when anything redefines cd afterwards. Hence the 90- prefix
# rather than living in 40-tools.zsh — the loader in ~/.zshrc sources
# ~/.config/zsh/*.zsh in lexical order, so this runs last.
#
# 50-tmux.zsh defines chpwd(), which zoxide's cd wrapper still triggers
# normally; that ordering is unchanged from the generated file.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
