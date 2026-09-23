# Shell functions — PLAN.MD task 2.6.

# lg: lazygit wrapper that follows lazygit's "open a new directory" action.
# Came from programs.lazygit.enableZshIntegration in interactive.nix; the
# generated body used no store paths, so it is transcribed verbatim.
function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    command lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
