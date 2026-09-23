#!/bin/sh
# Port of modules/home/claude.nix's `claudeAgentTools` activation script
# (PLAN.MD task 2.10).
#
# Claude Code rewrites ~/.claude/settings.json and ~/.claude.json at runtime
# (theme, onboarding, OAuth state), so NEITHER chezmoi nor Home Manager may
# own them. Instead the two tools that need an entry in those files ship
# idempotent merge installers, and we just run them:
#
#   rtk init -g --auto-patch   -> PreToolUse hook in ~/.claude/settings.json
#   codegraph install --target=claude -> MCP server entry in ~/.claude.json
#
# Both merge their own block and leave unrelated keys alone, so re-running is
# safe and a hand-edited settings.json survives. `run_onchange_` (not
# `run_once_`) so editing this script re-triggers it; the installers being
# idempotent makes the extra runs free.
set -eu

# chezmoi inherits the caller's PATH; when apply runs from a non-login shell
# the package-manager bindirs may be missing. Mirror dot_zshrc's PATH order.
for d in /nix/var/nix/profiles/default/bin "$HOME/.nix-profile/bin" \
         /opt/homebrew/bin "$HOME/.local/bin"; do
  if [ -d "$d" ]; then
    case ":$PATH:" in
      *":$d:"*) ;;
      *) PATH="$d:$PATH" ;;
    esac
  fi
done
export PATH

# Must exist before either installer writes into it.
mkdir -p "$HOME/.claude"

if command -v rtk >/dev/null 2>&1; then
  # --auto-patch: approve overwriting a stock hook block without prompting,
  # but never touch unrelated content — safe to re-run.
  RTK_TELEMETRY_DISABLED=1 rtk init -g --auto-patch
else
  echo "claude-agent-tools: rtk not on PATH, skipping hook install" >&2
fi

if command -v codegraph >/dev/null 2>&1; then
  # --target=claude: wire up Claude Code only, not every agent codegraph can
  # detect. --yes implies --location=global and is non-interactive.
  CODEGRAPH_TELEMETRY=0 codegraph install --yes --target=claude
else
  echo "claude-agent-tools: codegraph not on PATH, skipping MCP install" >&2
fi
